"""Original editable SVG assets. Python standard library; no downloaded artwork.

Run from any directory. Godot imports the SVGs directly. Deliberately avoid SVG
filters, masks, text and blend modes so the game's ThorVG importer stays portable.
"""
from pathlib import Path
import random
import math

ROOT = Path(__file__).resolve().parents[1] / 'thing-riot-v1/assets/midnight'
INK = '#20283b'
DEFS = '''<defs>
<linearGradient id="gold" x1="0" y1="0" x2="0.75" y2="1"><stop stop-color="#fff0ba"/><stop offset=".32" stop-color="#e7bd70"/><stop offset=".65" stop-color="#c18c47"/><stop offset="1" stop-color="#8d6038"/></linearGradient>
<linearGradient id="paper" x1="0" y1="0" x2=".7" y2="1"><stop stop-color="#fff7db"/><stop offset=".6" stop-color="#d7d3ba"/><stop offset="1" stop-color="#9baeb1"/></linearGradient>
<linearGradient id="coat" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#729ba4"/><stop offset=".5" stop-color="#426273"/><stop offset="1" stop-color="#263d53"/></linearGradient>
<linearGradient id="hood" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#b3acc9"/><stop offset=".45" stop-color="#7b789f"/><stop offset="1" stop-color="#474665"/></linearGradient>
<linearGradient id="baked" x1="0" y1="0" x2=".7" y2="1"><stop stop-color="#ffe4a4"/><stop offset=".6" stop-color="#d69a54"/><stop offset="1" stop-color="#9b6039"/></linearGradient>
<radialGradient id="pool"><stop stop-color="#e7bd70" stop-opacity=".15"/><stop offset="1" stop-color="#e7bd70" stop-opacity="0"/></radialGradient>
<radialGradient id="blue"><stop stop-color="#d0f9ef"/><stop offset=".3" stop-color="#8bdce5"/><stop offset="1" stop-color="#39718b"/></radialGradient>
</defs>'''

def svg(name, body, box, width=None, height=None):
    x, y, w, h = box
    p = ROOT / (name + '.svg')
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width or w}" height="{height or h}" viewBox="{x} {y} {w} {h}">{DEFS}<g stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>\n')

def path(d, fill, stroke=INK, sw=2):
    return f'<path d="{d}" fill="{alpha_fill(fill)}" stroke="{stroke}" stroke-width="{sw}"/>'

def alpha_fill(fill):
    if fill.startswith('#') and len(fill)==9:
        return fill[:7]+'" fill-opacity="'+str(round(int(fill[7:],16)/255,3))
    return fill

def ellipse(cx, cy, rx, ry, fill, stroke='none', sw=1):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{alpha_fill(fill)}" stroke="{stroke}" stroke-width="{sw}"/>'

def rect(x, y, w, h, fill, stroke='none', sw=1, r=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{alpha_fill(fill)}" stroke="{stroke}" stroke-width="{sw}"/>'

def line(x1,y1,x2,y2,c,sw=1):
    return path(f'M{x1} {y1}L{x2} {y2}', 'none',c,sw)

def clerk():
    b = ellipse(1,18,26,8,'#15233288')
    b += path('M-18 8L-21 19Q-10 24-5 18L-4 6M5 6L7 20Q20 24 24 17L18 5','#283347',INK,3)
    b += path('M-21-16Q-35-4-29 8L-19 6M20-15Q32-6 29 8L19 5','url(#coat)',INK,3)
    b += path('M-20-28L19-29Q27-17 25 6L14 14L0 10L-13 15L-26 5Q-29-15-20-28','url(#coat)',INK,3)
    b += path('M-12-29L0-3L13-29L8 8L-7 8','url(#paper)')
    b += path('M-13-24L-20-8L-7-11L-10 0L0 9M13-24L21-8L8-11L12 0L0 9','none','#9bb6b5',1.5)
    b += path('M-5-20L-11-24L-10-14L-4-17L4-17L10-14L11-24L5-20','#e7bd70')
    for y in [-9,-2,5]: b += ellipse(0,y,1.4,1.4,'#c19a62')
    b += path('M-23-54L15-61L24-52L23-29L-18-23L-27-30Z','#99afb0',INK,3)
    b += path('M-24-54L15-59L18-34L-22-27Z','url(#paper)',INK,2.5)
    b += path('M15-59L24-52L17-50Z','#fff5d5',INK,1.5)
    for y in [-49,-44,-39]: b += line(-20,y,-12,y-1,'#a5adb0',1)
    b += path('M-7-45Q-2-51 4-46M9-47L15-47','none',INK,2.4)
    b += ellipse(-3,-40,4.7,5.5,'#faf1d4',INK,1.5)+ellipse(10,-41,4.7,5.5,'#faf1d4',INK,1.5)
    b += ellipse(-1,-40,1.7,2.3,INK)+ellipse(11,-41,1.7,2.3,INK)+line(2,-41,5,-41,INK,1.5)
    b += path('M0-31Q5-34 11-32','none',INK,1.5)
    b += path('M-20-55L-18-66L7-69L13-58Z','#294b5b',INK,2)
    b += path('M-25-54Q-7-61 20-58','none',INK,4)+line(-14,-64,5,-66,'#a4c5c1',1.5)
    b += path('M-7-67Q-23-84-18-91Q-5-86-4-69','url(#paper)',INK,1.5)
    b += line(-17,-86,-7,-67,'#566979',1)
    b += path('M21-12L35-18L41 5L26 10Z','url(#paper)',INK,2)
    b += line(28,-9,35,-11,'#7c8f99',1)+line(29,-4,36,-6,'#7c8f99',1)
    b += ellipse(29,1,3.5,3.5,'#b18260',INK,1.5)
    svg('enemies/clerk',b,(-48,-96,96,124))

def charger():
    b = ellipse(0,20,33,9,'#15233299')
    for x in [-24,-10,13,27]:
        b += path(f'M{x-4} 1L{x-6} 19L{x+4} 21L{x+7} 0','#344556',INK,3)
    b += path('M-32-23Q-28-45 3-48Q24-47 31-22L31 7Q10 18-21 11L-35 1Z','url(#gold)',INK,3)
    b += path('M-26-25Q-15-40 9-40L27-29L23-16L-23-15Z','#536c79',INK,2)
    b += path('M-19-38L-12-47L12-46L20-36L13-28L-14-28Z','#c8cbb7',INK,2)
    b += path('M-7-46L-1-68L8-45Z','url(#gold)',INK,2)
    b += path('M-27-20L-24-4L-13 4L20 1L31-8L27-23Z','#b1b6ad',INK,3)
    b += path('M-20-22L-10-15L-23-14M14-18L24-25L27-16','none',INK,3)
    b += line(-21,-17,-13,-16,'#fff0c5',2)+line(17,-18,24,-20,'#fff0c5',2)
    b += path('M-13-5L20-7L22 8L-14 10Z','url(#gold)',INK,2)
    b += rect(-8,-3,26,6,INK,r=2)+line(-7,-4,16,-6,'#fff0c5',1.3)
    b += path('M-17-1Q-32 0-31-15Q-20-8-17-9M22-3Q38-7 31-22Q29-12 22-12','url(#paper)',INK,2)
    b += path('M-31-33L-39-30L-34-12L-26-16Z','#6d7f88',INK,2)
    for x,y in [(-26,-26),(25,-29),(-20,4),(25,1),(-11,-38),(13,-38)]:
        b += ellipse(x,y,2,2,'#fff0c5',INK,1)
    svg('enemies/charger',b,(-48,-76,96,106))

def caster():
    b = ellipse(1,18,27,8,'#15233299')
    b += path('M-9-49Q-24-25-29 13L-15 11L-8 22L2 14L15 21L26 10Q18-26 9-50','url(#hood)',INK,3)
    b += path('M-8-24L-16 10L-8 6M11-23L18 12L9 6','none','#b7a9c5',2)
    b += path('M-20-39L-8-63L4-71L7-60Q22-54 23-36L13-20L-12-23Z','url(#hood)',INK,3)
    b += path('M-12-40Q0-55 15-38L10-26L-10-28Z','#18273d',INK,2)
    b += ellipse(-5,-36,2.4,1.8,'#b6f3f1')+ellipse(7,-36,2.4,1.8,'#b6f3f1')
    b += path('M-20-23L-37-9L-28-3L-14-13M18-23L32-16L36-24L22-31','url(#hood)',INK,2.5)
    b += path('M-14-29L-3-19L12-29L7-10L-6-10Z','url(#paper)',INK,2)
    b += rect(-7,-10,14,17,'#2f5268',INK,2,3)+ellipse(0,-9,7,3,'#77a4b0',INK,1)
    b += path('M-3-5L2-7L5 0L1 3L-3 1Z','#b5dde0','none')
    b += path('M30 15L32-54','none','#aa8e65',4)
    b += path('M25-55L33-62L40-55L33-44Z','url(#gold)',INK,2)
    b += ellipse(33,-55,7,8,'url(#blue)',INK,1.5)+ellipse(31,-58,2,2,'#efffef')
    b += path('M-38-15L-22-19L-19-3L-35 2Z','url(#paper)',INK,1.5)
    b += line(-33,-9,-25,-11,'#546e83',1)+line(-32,-5,-25,-7,'#546e83',1)
    svg('enemies/caster',b,(-48,-80,96,112))

def crown():
    b = path('M-36-23L-18-9L0-33L18-9L36-23L27 26L-27 26Z','url(#gold)',INK,3)
    b += path('M-29-16L-23 11L23 11L29-16L17-3L0-24L-17-3Z','#f5d58a','#9c6c35',1.5)
    b += path('M-25 12L25 12L25 24L-25 24Z','#b98240',INK,2)
    b += path('M-26 13L25 13M-24 23L24 23','none','#fff0b9',2)
    for x in [-18,0,18]:
        b += path(f'M{x} 14L{x+4} 18L{x} 22L{x-4} 18Z','url(#blue)',INK,1)
    for x,y in [(-36,-24),(0,-34),(36,-24)]: b += ellipse(x,y,4,4,'#ffe6a4',INK,1.5)
    b += path('M-4-11L0-17L4-11L0-5Z','#bcecf1',INK,1)
    b += line(-23,-5,-19,7,'#fff8db',2)+line(4,-20,14,-7,'#fff8db',1.5)
    svg('weapons/crown',b,(-44,-42,88,76))

def biscuit():
    rng=random.Random(42)
    b=ellipse(1,5,30,29,'#6d4536',INK,3)
    pts=[]
    for i in range(64):
        a=i*math.tau/64; r=30 if i%4 in [1,2] else 28
        pts.append(f'{math.cos(a)*r:.2f},{math.sin(a)*r:.2f}')
    b+=path('M'+'L'.join(pts)+'Z','url(#baked)',INK,2.5)
    b+=ellipse(0,0,24,24,'none','#b0793f',1.5)+path('M-22-8Q-16-27 7-22','none','#fff0b8',2)
    for x,y in [(-12,-11),(1,-14),(13,-7),(-13,4),(0,0),(12,9),(-3,15)]:
        b+=path(f'M{x-3} {y-2}L{x+2} {y-3}L{x+4} {y+1}L{x} {y+4}L{x-3} {y+2}Z','#75462f','#a26837',1)
        b+=line(x-2,y-2,x+1,y-2,'#e3b37a',1)
    for _ in range(30):
        x,y=rng.uniform(-20,20),rng.uniform(-20,20)
        if x*x+y*y<480: b+=ellipse(round(x,2),round(y,2),.6,.7,'#b48048')
    svg('weapons/biscuit',b,(-36,-36,72,78))

def die():
    b=path('M-32-29L25-29L33-21L33 30L25 38L-29 35L-35 27L-35-21Z','#162338',INK,2)
    b+=path('M-29 22L25 22L31 29L25 35L-27 32Z','#a7967c','#675e59',1.5)
    b+=path('M24-25L31-20L31 29L24 25Z','#c7bba2','#897e71',1)
    b+=rect(-32,-28,58,55,'url(#paper)',INK,2.5,8)
    b+=path('M-27 16L-27-17Q-27-23-21-23L17-23','none','#fffdef',2)
    b+=path('M-26 22L18 22Q22 22 22 17','none','#c4b496',2)
    svg('weapons/die',b,(-42,-38,84,82))

def floor():
    rng=random.Random(417); b=rect(0,0,768,768,'#293d4b')
    # The tessellation meets at the texture edges. Broad value variation, fine seams.
    colors=['#314653','#334956','#354a57','#364b58','#304450','#394e59','#344853']
    for y in range(0,768,96):
        for x in range(-128,768,128):
            px=x+(64 if y//96%2 else 0)
            b+=rect(px+2,y+2,124,92,rng.choice(colors),'#233744',1.5,5)
            b+=path(f'M{px+8} {y+91}L{px+119} {y+91}','none','#263b49',2)
            b+=path(f'M{px+8} {y+5}L{px+113} {y+5}','none','#526670',.9)
            if rng.random()<.26:
                b+=path(f'M{px+47} {y+2}l-7 16 12 10-3 19','none','#263b48',1.5)
            for _ in range(7):
                sx=px+rng.randint(9,111);sy=y+rng.randint(12,82)
                b+=line(sx,sy,sx+rng.randint(2,7),sy,'#425664',.65)
    # Moss follows mortar, kept below enemy luminance.
    for _ in range(48):
        x=rng.randint(5,756);y=rng.choice(range(0,769,96))+rng.randint(-3,3)
        b+=ellipse(x,y,rng.randint(3,11),rng.randint(1,3),'#4e6666')
    svg('arena/slate',b,(0,0,768,768))

def medallion():
    b=ellipse(0,0,252,194,'#233744')+ellipse(0,0,246,188,'#40525b','#778278',2)
    b+=ellipse(0,0,233,176,'#344853','#263846',5)+ellipse(0,0,222,166,'none','#8c9079',2)
    for i in range(32):
        a=i*math.tau/32
        b+=line(round(math.cos(a)*225,2),round(math.sin(a)*168,2),round(math.cos(a)*235,2),round(math.sin(a)*178,2),'#7e8879',2)
    b+=path('M-111-55L-60-17L0-83L60-17L111-55L82 67L-82 67Z','#52636a','#98957b',3)
    b+=path('M-84 37L84 37M-77 52L77 52','none','#999b83',3)
    b+=path('M-8-23L0-36L8-23L0-10Z','#899783','#303e4b',2)
    for side in [-1,1]:
        for i in range(7):
            x=side*(114+i*7); y=88-i*23
            b+=path(f'M{x} {y}q{side*24} -20 {side*8} -31q{-side*23} 13 {-side*8} 31Z','#697b77','#344854',1)
    b+=path('M-196-102l35 20 12-7 38 27M88 150l-26-28 9-19-20-24','none','#263a47',3)
    svg('arena/medallion',b,(-264,-206,528,412))

def garden():
    rng=random.Random(55); b=ellipse(0,10,102,44,'#243743')
    for i in range(9):
        x=-84+i*21; y=15+math.sin(i)*6
        b+=path(f'M{x-12} {y-12}l22-5 9 15-5 12-25-2Z','#50636b','#253945',2)
        b+=path(f'M{x-9} {y-11}l16-3 7 10','none','#798377',2)
    for i in range(35):
        x=rng.randint(-86,86); y=rng.randint(-9,15); h=rng.randint(12,40); s=rng.choice([-1,1])
        b+=path(f'M{x} {y}q{-s*10} {-h*.5} {s*6} {-h}q{s*13} {h*.7} {-s*6} {h}Z',rng.choice(['#4c686b','#587578','#627e7c','#3b5b63']),'#2b434d',.8)
    svg('arena/garden',b,(-115,-55,230,110))

def lamp():
    b=ellipse(0,25,115,70,'url(#pool)')+ellipse(0,14,26,10,'#192d3a88')
    b+=path('M-14 7L13 7L20 18L-21 18Z','#384957',INK,2)+rect(-6,-50,12,58,'url(#gold)',INK,2,2)
    b+=path('M-19-73L19-73L13-45L-13-45Z','#8b805f',INK,3)
    b+=path('M-13-69L13-69L9-49L-9-49Z','#dfc28a',INK,1.5)
    b+=path('M-20-74L0-90L20-74Z','#56717a',INK,2)+line(0,-89,0,-97,'#b09c6d',3)
    b+=line(0,-69,0,-49,'#785f42',2)+line(-17,-73,17,-73,'#edcf93',2)
    svg('arena/lamp',b,(-120,-102,240,200))

def crate():
    b=ellipse(0,26,35,9,'#182c3b88')
    b+=path('M-30-29L23-34L33-23L33 28L-25 33L-33 24Z','#6d533f',INK,3)
    b+=path('M-29-25L21-29L23 22L-29 27Z','url(#baked)',INK,2)
    for y in [-12,2,16]: b+=line(-27,y,21,y-4,'#8d603f',2)+line(-24,y+2,19,y-1,'#e1b47b',.8)
    b+=path('M23-28L30-21L30 25L24 23Z','#956c46',INK,2)
    b+=path('M-27 21L16-24L22-20L-22 26Z','#c89961','#705139',1.5)
    for x in [-27,20]:
        b+=rect(x-3,-25,6,9,'#687b83',INK,1,1)+rect(x-3,17,6,10,'#687b83',INK,1,1)
        b+=ellipse(x,-21,1,1,'#c0c6ba')+ellipse(x,21,1,1,'#c0c6ba')
    svg('arena/crate',b,(-42,-42,84,84))

def boss():
    # Body only; legs and independently articulated stamping claws remain in Godot.
    b=path('M-45-53Q-63-26-55 23L-37 51L0 60L38 49L57 22Q61-30 40-51Z','url(#hood)',INK,4)
    b+=path('M-30-51L0 33L30-51L21 43L-18 43Z','url(#paper)',INK,2)
    b+=path('M-30-47L-45-18L-26-17L-33-5L0 38M30-47L45-18L26-17L33-5L0 38','url(#hood)',INK,2)
    b+=path('M-7-37L7-37L11-27L0-15L-11-27Z','url(#gold)',INK,2)
    b+=path('M0-17L-8 11L0 25L8 11Z','url(#gold)',INK,2)
    for y in [34,44]: b+=ellipse(1,y,2.5,2.5,'#cda363',INK,1)
    b+=path('M29 9L49 6L48 18L29 20Z','#3e4562',INK,1.5)+path('M31 8L35 0L40 7L46-1L46 7Z','#fff0c5',INK,1)
    b+=path('M-30 34Q-1 42 28 33L24 42L-27 43Z','#faf0cf',INK,2)
    for x in [-24,24]:
        b+=path(f'M{x} -46L{x} -69','none','#aa9377',10)+path(f'M{x-2} -48L{x-2} -67','none','#e4ca9f',3)
        b+=ellipse(x,-75,17,16,'url(#paper)',INK,3)+ellipse(x,-73,5,6,INK)+ellipse(x-2,-76,1.5,2,'#fffde9')
        b+=ellipse(x,-75,19,18,'none','#aa956c',2)+line(x-10,-84,x+1,-89,'#fff6d3',1.5)
    b+=path('M-5-76Q0-79 5-76','none',INK,3)
    b+=path('M-41-92L-20-89M18-89L40-94','none',INK,5)
    b+=path('M-48 23Q-26 18-18 33','none','#a4a1b4',1.5)
    svg('enemies/bureaucrab',b,(-70,-102,140,168))

if __name__ == '__main__':
    for draw in [clerk,charger,caster,crown,biscuit,die,floor,medallion,garden,lamp,crate,boss]: draw()
    print(f'Built 12 original SVG assets in {ROOT}')
