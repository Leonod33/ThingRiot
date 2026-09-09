"""Compose and render Thing Riot's original score and material sound library.

Dependencies: Python, numpy, scipy, ffmpeg. No external samples or model weights.
All randomness is seeded offline. Runtime never synthesizes buffers or consumes
the gameplay RNG. Loop tails are folded into the start before Ogg encoding.
"""
from pathlib import Path
import math
import subprocess
import tempfile
import json
import numpy as np
from scipy import signal
from scipy.io import wavfile

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'thing-riot-v1/assets/audio'
RATE=32000
BEAT=60/112
RNG=np.random.default_rng(9042)
REPORT={}

def hz(midi): return 440*2**((midi-69)/12)
def time(duration): return np.arange(round(duration*RATE),dtype=np.float64)/RATE
def fade(y, attack=.003, release=.02):
    y=y.copy(); n=len(y); a=min(n,round(attack*RATE)); r=min(n,round(release*RATE))
    if a: y[:a]*=np.linspace(0,1,a)
    if r: y[-r:]*=np.linspace(1,0,r)
    return y
def noise(t, cutoff=6000, high=400):
    n=RNG.uniform(-1,1,len(t))
    return signal.sosfilt(signal.butter(2,[high,cutoff],btype='bandpass',fs=RATE,output='sos'),n)

def instrument(note,duration,kind):
    t=time(duration); f=hz(note); y=np.zeros_like(t)
    if kind in ['pluck','keys']:
        # Short string/harpsichord attack, progressively faster harmonic damping.
        for h in range(1,10 if kind=='keys' else 6):
            y+=np.sin(2*np.pi*f*h*t+(h%2)*.12)/h**1.35*np.exp(-t*(2.5+h*1.65))
        y+=noise(t,5000,1400)*np.exp(-t*90)*.2
        return fade(y,.002,.045)
    if kind=='bass':
        y=(np.sin(2*np.pi*f*t)+.32*np.sin(2*np.pi*f*2*t)+.14*np.sin(2*np.pi*f*3*t))*np.exp(-t*3.5)
        return fade(y,.012,.06)
    if kind=='bell':
        for ratio,amp,decay in [(1,1,2),(2.01,.34,4),(2.76,.16,7),(4.08,.06,9)]:
            y+=np.sin(2*np.pi*f*ratio*t)*amp*np.exp(-t*decay)
        return fade(y,.002,.09)
    if kind in ['strings','brass']:
        for h in range(1,9):
            weight=1/h**1.8 if kind=='strings' else (1/h**1.35 if h<5 else .025)
            vib=.015*np.sin(2*np.pi*4.8*t)
            y+=(np.sin(2*np.pi*f*h*t+vib)+.45*np.sin(2*np.pi*f*1.002*h*t))*weight
        envelope=np.minimum(t/(.16 if kind=='strings' else .04),1)*np.minimum((duration-t)/.23,1)
        return y*envelope*.45
    raise ValueError(kind)

def drum(kind,duration=.3):
    t=time(duration)
    if kind=='kick':
        phase=2*np.pi*(48*t+65*.035*(1-np.exp(-t/.035)))
        y=np.sin(phase)*np.exp(-t*17)+noise(t,7000,2800)*np.exp(-t*180)*.15
    elif kind=='snare':
        y=noise(t,9500,950)*np.exp(-t*24)*1.2+np.sin(2*np.pi*178*t)*np.exp(-t*35)*.32
    elif kind=='hat': y=noise(t,13000,5500)*np.exp(-t*65)*.5
    elif kind=='wood':
        y=(np.sin(2*np.pi*650*t)+.6*np.sin(2*np.pi*1060*t))*np.exp(-t*75)
    elif kind=='tom':
        y=np.sin(2*np.pi*(78*t+13*.08*(1-np.exp(-t/.08))))*np.exp(-t*10)
    else: raise ValueError(kind)
    return fade(y,.001,.02)

def add(buf,y,start,level=1,pan=0,loop=False):
    n=len(buf); pos=round(start*RATE)
    angle=(pan+1)*math.pi/4
    stereo=y[:,None]*np.array([math.cos(angle),math.sin(angle)])[None,:]*level
    if loop:
        ix=(pos+np.arange(len(y)))%n
        np.add.at(buf,ix,stereo)
    else:
        if pos>=n: return
        count=min(len(y),n-pos);buf[pos:pos+count]+=stereo[:count]

def room(buf,loop=False,amount=.12):
    dry=buf.copy()
    for delay,gain in [(.047,.6),(.079,.46),(.127,.33),(.193,.25),(.293,.16)]:
        frames=round(delay*RATE)
        reflection=np.roll(dry[:,::-1],frames,axis=0)
        if not loop: reflection[:frames]=0
        buf+=reflection*gain*amount
    return buf

def export(name,buf,loop=False):
    # Remove DC and tame peaks. Music is subsequently normalized as an entire
    # arrangement, retaining its rests and instrumentation dynamics.
    buf-=buf.mean(axis=0)
    peak=float(np.max(np.abs(buf)))
    if peak>0: buf*=.72/peak
    dest=OUT/(name+'.ogg'); dest.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='riot-audio-') as tmp:
        src=Path(tmp)/'source.wav'
        wavfile.write(src,RATE,(buf*32767).astype(np.int16))
        subprocess.run(['ffmpeg','-v','error','-y','-i',str(src),'-c:a','libvorbis','-q:a','5',str(dest)],check=True)
    REPORT[name]={'seconds':round(len(buf)/RATE,4),'source_peak_db':round(20*np.log10(np.max(np.abs(buf))+1e-12),2),'source_rms_db':round(20*np.log10(np.sqrt(np.mean(buf**2))+1e-12),2),'loop':loop}
    if loop: REPORT[name]['loop_boundary_delta']=round(float(np.max(np.abs(buf[-1]-buf[0]))),6)

def compose(stage):
    total=BEAT*4*32; buf=np.zeros((round(total*RATE),2))
    # D minor, Bb, G minor, A7; the boss adds the flattened second and a low pedal.
    chords=[(50,57,62,65),(50,57,62,65),(46,53,58,62),(43,50,55,58),
            (50,57,62,65),(45,52,57,61),(43,50,55,58),(45,52,57,61)]
    themes=[
        [(0,74,1), (1.5,77,.5),(2,81,1),(3.5,77,.5)],
        [(.5,76,.5),(1.5,74,.5),(2.5,69,1)],
        [(0,74,1.5),(2,77,.5),(3,79,.7)],
        [(.5,77,.5),(1.5,74,.5),(2.5,70,.7)],
        [(0,69,.6),(1,74,.6),(2,77,.6),(3,81,.7)],
        [(0,80,.6),(1,76,.6),(2.5,73,1)],
        [(.5,74,.5),(1.5,70,.5),(2.5,67,.8)],
        [(0,73,.6),(1.5,76,.6),(3,69,.6)],
    ]
    for bar in range(32):
        start=bar*4*BEAT; chord=chords[bar%8]; section=bar//8
        sparse=section==2 and bar%8<4
        if stage==2 and bar%8 in [1,5]: chord=(46,53,58,63)
        root=chord[0]-12
        # Root/fifth walking bass leaves the melody plenty of space.
        for beat,note in [(0,root),(2,root+7)]+([(3.5,root+12)] if stage>0 and not sparse else []):
            add(buf,instrument(note,BEAT*.9,'bass'),start+BEAT*beat,.27,0,True)
        for step in range(8):
            if sparse and step%2: continue
            if stage==0 and step in [3,7]: continue
            note=chord[[0,2,1,3,0,2,1,3][step]]+12
            swing=.065 if step%2 else 0
            add(buf,instrument(note,.48,'pluck'),start+(step*.5+swing)*BEAT,.10 if stage==0 else .115,-.36,True)
        if bar%8 not in [6,7] or stage>0:
            for i,note in enumerate(chord[1:]):
                add(buf,instrument(note+12,BEAT*3.7,'strings'),start,.075 if sparse else (.12 if stage==2 else .095),-.55+i*.5,True)
        if not sparse and (section!=0 or bar>1):
            theme=themes[bar%8]
            for beat,note,dur in theme:
                if stage==2: note-=12
                add(buf,instrument(note,BEAT*max(1,dur),'brass' if stage==2 else 'keys'),start+beat*BEAT,.16 if stage==2 else .15,.25,True)
        # A brief answering phrase only at cadences, not a permanent high ostinato.
        if bar%8 in [3,7] and section!=2:
            for i,note in enumerate([chord[2]+24,chord[1]+24]):
                add(buf,instrument(note,1.4,'bell'),start+(2.5+i*.75)*BEAT,.047,.48,True)
        if not sparse:
            for beat in [0,2]: add(buf,drum('kick'),start+beat*BEAT,.20 if stage==0 else .32,0,True)
            for beat in [1,3]: add(buf,drum('wood' if stage==0 else 'snare'),start+beat*BEAT,.075 if stage==0 else .13,.1,True)
            for eighth in range(8):
                add(buf,drum('hat',.16),start+(eighth*.5+.04*(eighth%2))*BEAT,.075 if eighth%2 else .045,.4 if eighth%2 else -.35,True)
        if stage==2 and bar%4==3:
            for i in range(3): add(buf,drum('tom',.6),start+(2.5+i*.5)*BEAT,.24,(-.3+i*.3),True)
    room(buf,True,.22)
    return buf

def material(kind,variant=0):
    f=1+(variant-1)*.06
    duration={'crown':.32,'crown_hit':.38,'catch':.2,'biscuit':.23,'crunch':.32,'throw_die':.22,'clack':.2,'dice':.6,'stamp':.65,'hurt':.34,'bomb':.8,'spring':.4,'pickup':.2}.get(kind,.3)
    t=time(duration);y=np.zeros_like(t)
    if kind in ['crown','crown_hit','catch']:
        base={'crown':820,'crown_hit':1150,'catch':640}[kind]*f
        for ratio,level,decay in [(1,.5,16),(2.76,.22,24),(4.07,.12,30)]:
            y+=np.sin(2*np.pi*base*ratio*t)*level*np.exp(-t*decay)
        y+=noise(t,10000,1800)*np.sin(np.pi*np.minimum(t/.14,1))**2*np.exp(-t*15)*(.45 if kind=='crown' else .15)
    elif kind in ['biscuit','crunch']:
        y=noise(t,6500,700)*np.exp(-t*24)*.6
        for i in range(5 if kind=='crunch' else 2):
            start=.012+i*.027*f
            tau=np.maximum(t-start,0)
            y+=(t>=start)*noise(t,10000,2400)*np.exp(-tau*100)*.3
        y+=np.sin(2*np.pi*145*f*t)*np.exp(-t*45)*.35
    elif kind in ['throw_die','clack']:
        for ratio,level in [(1,.65),(1.54,.24),(2.63,.12)]:
            y+=np.sin(2*np.pi*420*f*ratio*t)*np.exp(-t*(35+ratio*7))*level
        y+=noise(t,7500,900)*np.exp(-t*65)*.4
    elif kind in ['dice','stamp','bomb','hurt']:
        base={'dice':66,'stamp':49,'bomb':43,'hurt':104}[kind]*f
        phase=2*np.pi*(base*t+65*.028*(1-np.exp(-t/.028)))
        y=np.sin(phase)*np.exp(-t*9)*.75+noise(t,6000,180)*np.exp(-t*15)*.65
        y+=np.sin(2*np.pi*base*2.73*t)*np.exp(-t*24)*.12
        if kind=='stamp':
            tau=np.maximum(0,t-.055)
            y+=(t>.055)*noise(t,8500,1200)*np.exp(-tau*22)*.24
    elif kind=='spring':
        y=np.sin(2*np.pi*(180*f*t+700*f*t*t))*np.exp(-t*11)*.6+np.sin(2*np.pi*700*f*t)*np.exp(-t*35)*.2
    elif kind=='pickup':
        y=np.sin(2*np.pi*hz(86)*f*t)*np.exp(-t*22)*.3+np.sin(2*np.pi*hz(93)*t)*np.exp(-t*28)*.15
    y=fade(y,.002,.035)
    buf=np.zeros((len(y),2));add(buf,y,0,1,0)
    return room(buf,False,.10)

def motif(kind):
    notes={'six':[74,77,81,86],'crumble':[69,74,77],'unlock':[62,69,74,77,81],
           'arrival':[38,None,38,39,None,33], 'victory':[62,65,69,None,74,77,81,86]}[kind]
    beat=.12 if kind!='arrival' else .19
    buf=np.zeros((round((len(notes)*beat+.65)*RATE),2))
    for i,n in enumerate(notes):
        if n is None: continue
        add(buf,instrument(n,.8,'brass' if kind=='arrival' else 'bell'),i*beat,.6,(i%3-1)*.2)
        if kind in ['six','unlock','victory']: add(buf,instrument(n-12,.55,'keys'),i*beat,.18,-.25)
    return room(buf,False,.24)

def main():
    global RNG
    OUT.mkdir(exist_ok=True,parents=True)
    for stage,title in enumerate(['royal_clockwork','paperwork_pursuit','the_final_audit']):
        RNG=np.random.default_rng(9042+stage)
        export('music/'+title,compose(stage),True)
        print('Composed',title,flush=True)
    kinds=['crown','crown_hit','catch','biscuit','crunch','throw_die','clack','dice','stamp','hurt','bomb','spring','pickup']
    bank={}
    for i,kind in enumerate(kinds):
        paths=[]
        for v in range(1 if kind=='hurt' else 3):
            RNG=np.random.default_rng(1200+i*10+v)
            name=f'sfx/{kind}_{v+1}';export(name,material(kind,v));paths.append(name+'.ogg')
        bank[kind]=paths
    for kind in ['six','crumble','unlock','arrival','victory']:
        export('sfx/'+kind,motif(kind));bank[kind]=['sfx/'+kind+'.ogg']
    code='extends RefCounted\n# Generated by tools/build_midnight_audio.py; original synthesized recordings.\nconst VARIANTS = {\n'
    for kind,paths in bank.items():
        code+='\t"'+kind+'":['+','.join('preload("res://assets/audio/'+p+'")' for p in paths)+'],\n'
    code+='}\nconst MUSIC = [\n'
    for title in ['royal_clockwork','paperwork_pursuit','the_final_audit']:
        code+='\tpreload("res://assets/audio/music/'+title+'.ogg"),\n'
    code+=']\n'
    (ROOT/'thing-riot-v1/polish/audio_bank.gd').write_text(code)
    (ROOT/'docs/audio-render-report.json').write_text(json.dumps(REPORT,indent=2)+'\n')
    print(f'Rendered {len(REPORT)} original recordings',flush=True)
if __name__=='__main__': main()
