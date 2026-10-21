"""Иконка BookNest: открытая книга в гнезде на seed-цвете темы (0xFF2F5D50).

Генерирует два PNG 1024×1024 для flutter_launcher_icons:
  assets/icon/icon.png        — полная иконка (фон + рисунок), legacy-иконки;
  assets/icon/foreground.png  — только рисунок на прозрачном фоне, adaptive-иконка
                                Android 8+ (фон — цвет из pubspec).
Запуск: python tool/make_icon.py  (нужен Pillow).
"""
from pathlib import Path

from PIL import Image, ImageDraw

SEED = (0x2F, 0x5D, 0x50, 255)  # тот же цвет, что ColorScheme.fromSeed
PAGE = (0xF4, 0xEC, 0xD8, 255)  # бумага
LINE = (0x9F, 0xB8, 0xA8, 255)  # строки текста
NEST = (0xC9, 0x93, 0x4A, 255)  # прутья гнезда
NEST_DARK = (0xA0, 0x70, 0x34, 255)

SS = 4  # суперсэмплинг: рисуем крупно, уменьшаем — гладкие края
SIZE = 1024 * SS


def bezier(p0, p1, p2, n=40):
    """Квадратичная кривая Безье как список точек."""
    return [
        (
            (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1],
        )
        for t in (i / n for i in range(n + 1))
    ]


def s(*xy):
    """Координаты макета 1024 → холст с суперсэмплингом."""
    return tuple(v * SS for v in xy)


def draw_glyph(d: ImageDraw.ImageDraw, scale: float):
    """Рисунок в квадрате 1024, сжатый к центру в [scale] раз."""

    def p(x, y):
        y -= 30  # рисунок занимает y 250…800 — сдвиг к оптическому центру
        return s(512 + (x - 512) * scale, 512 + (y - 512) * scale)

    def w(v):
        return max(1, round(v * scale * SS))

    def box(cx, cy, rx, ry):
        return [p(cx - rx, cy - ry), p(cx + rx, cy + ry)]

    # Гнездо: обод (эллипс) и чаша (нижняя половина эллипса).
    cx, cy, rx = 512, 650, 312

    # 1) задний край обода — за книгой
    d.ellipse(box(cx, cy, rx, 62), fill=NEST_DARK)

    # 2) раскрытая книга: страницы с выгнутым верхом, низ уходит в гнездо
    spine_top, spine_bot = (512, 320), (512, 700)
    for side in (-1, 1):
        outer_top = (512 + side * 280, 290)
        outer_bot = (512 + side * 280, 670)
        top = bezier(spine_top, (512 + side * 135, 240), outer_top)
        bottom = bezier(outer_bot, (512 + side * 135, 630), spine_bot)
        d.polygon([p(*q) for q in top + bottom], fill=PAGE)
        # строки текста повторяют изгиб страницы
        for k in range(4):
            off = 70 + k * 56
            a = (512 + side * 40, spine_top[1] + off - 4)
            b = (512 + side * 250, outer_top[1] + off + 4)
            c = (512 + side * 145, 250 + off)
            d.line(
                [p(*q) for q in bezier(a, c, b, 30)],
                fill=LINE, width=w(14), joint="curve",
            )
    d.line([p(*spine_top), p(*spine_bot)], fill=SEED, width=w(12))

    # 3) чаша гнезда — поверх низа книги: книга «лежит» в гнезде
    d.chord(box(cx, cy, rx, 170), start=0, end=180, fill=NEST)
    # передний край обода — толстая дуга
    d.arc(box(cx, cy, rx, 62), start=0, end=180, fill=NEST_DARK, width=w(26))
    # прутья — дуги внутри чаши
    for rxi, top, bottom, a0, a1 in (
        (262, 570, 770, 25, 155),
        (200, 600, 790, 30, 150),
        (285, 640, 740, 15, 165),
    ):
        d.arc(
            [p(cx - rxi, top), p(cx + rxi, bottom)],
            start=a0, end=a1, fill=NEST_DARK, width=w(12),
        )


def render(background, scale):
    img = Image.new("RGBA", (SIZE, SIZE), background)
    draw_glyph(ImageDraw.Draw(img), scale)
    return img.resize((1024, 1024), Image.LANCZOS)


out = Path(__file__).resolve().parent.parent / "assets" / "icon"
out.mkdir(parents=True, exist_ok=True)
render(SEED, 0.92).save(out / "icon.png")
# Adaptive: лаунчер обрезает до круга/капли — рисунок в безопасной зоне 66/108.
render((0, 0, 0, 0), 0.76).save(out / "foreground.png")
print("written:", out)
