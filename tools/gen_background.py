import random
import sys

TOP = 480
random.seed(7)
stars = []
for _ in range(110):
    x, y = random.uniform(0, 1280), random.uniform(0, TOP + 560)
    r = random.choice([1.2, 1.5, 1.8, 2.2, 2.6])
    o = random.uniform(0.35, 0.9)
    stars.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="#FFF4D6" opacity="{o:.2f}"/>')
twinkles = []
for x, y, s in [(330, 90, 9), (600, 60, 7), (470, 210, 6), (760, 150, 8), (980, 300, 7), (300, 380, 6), (700, 420, 7),
                (880, 520, 5), (420, -120, 8), (820, -60, 7), (560, -300, 9), (950, -380, 6), (300, -420, 7)]:
    y += TOP
    twinkles.append(f'<path d="M{x} {y-s} Q{x+s*0.15} {y-s*0.15} {x+s} {y} Q{x+s*0.15} {y+s*0.15} {x} {y+s} '
                    f'Q{x-s*0.15} {y+s*0.15} {x-s} {y} Q{x-s*0.15} {y-s*0.15} {x} {y-s} Z" fill="#FFF6DC" opacity="0.85"/>')
H = TOP + 720
f = lambda y: (y + TOP) / H
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="{H}" viewBox="0 0 1280 {H}">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#232550"/>
      <stop offset="{f(0):.3f}" stop-color="#2F3262"/>
      <stop offset="{f(396):.3f}" stop-color="#57518E"/>
      <stop offset="1" stop-color="#9483B6"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#C4E8FF" stop-opacity="0.4"/>
      <stop offset="1" stop-color="#C4E8FF" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="earth" cx="0.36" cy="0.34" r="0.72">
      <stop offset="0" stop-color="#D3F1FC"/>
      <stop offset="1" stop-color="#88C0E0"/>
    </radialGradient>
    <clipPath id="earthClip"><circle cx="900" cy="{130+TOP}" r="44"/></clipPath>
  </defs>
  <rect width="1280" height="{H}" fill="url(#sky)"/>
  {"".join(stars)}
  {"".join(twinkles)}
  <g transform="translate(0 {TOP})">
    <circle cx="900" cy="130" r="92" fill="url(#glow)"/>
    <circle cx="900" cy="130" r="44" fill="url(#earth)"/>
  </g>
  <g clip-path="url(#earthClip)">
    <g transform="translate(0 {TOP})">
      <path d="M864 104 C878 92 896 98 892 112 C888 124 902 128 898 142 C893 156 870 150 866 136 C862 124 852 114 864 104 Z" fill="#BFE8C4"/>
      <path d="M918 150 C930 142 948 150 944 164 C940 176 920 178 914 168 C910 160 912 154 918 150 Z" fill="#BFE8C4"/>
      <path d="M922 98 C930 92 942 96 940 106 C938 114 926 114 922 108 Z" fill="#BFE8C4"/>
      <path d="M852 128 C866 122 878 126 890 122 M904 118 C918 112 934 116 950 110 M870 160 C884 154 900 158 912 152" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity="0.75"/>
    </g>
  </g>
  <g transform="translate(0 {TOP})">
    <circle cx="900" cy="130" r="44" fill="none" stroke="#6FA6C9" stroke-width="3"/>
    <ellipse cx="884" cy="110" rx="10" ry="6" transform="rotate(-35 884 110)" fill="#FFFFFF" opacity="0.5"/>
    <path d="M0 628 C120 596 220 612 320 604 C440 594 520 622 640 610 C760 598 860 620 960 608 C1080 596 1180 614 1280 600 L1280 720 L0 720 Z" fill="#B9AED0"/>
    <ellipse cx="420" cy="618" rx="30" ry="6" fill="#A99DC2"/>
    <ellipse cx="860" cy="622" rx="22" ry="5" fill="#A99DC2"/>
    <path d="M0 662 C140 640 300 654 420 646 C560 636 700 658 840 648 C980 638 1120 656 1280 644 L1280 720 L0 720 Z" fill="#A497C2"/>
    <ellipse cx="560" cy="662" rx="34" ry="7" fill="#9488B5"/>
    <ellipse cx="760" cy="668" rx="18" ry="4" fill="#9488B5"/>
    <ellipse cx="330" cy="664" rx="16" ry="4" fill="#9488B5"/>
  </g>
</svg>
'''
open(sys.argv[1], 'w').write(svg)
