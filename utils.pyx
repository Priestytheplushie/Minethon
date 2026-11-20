import pygame
import hashlib

pygame.font.init()
font = pygame.font.Font("assets/fonts/Minecraft.otf", 16)

WIDTH = 800
HEIGHT = 600
WORLD_COLUMNS = (WIDTH // 16) * 10
WORLD_WIDTH = WORLD_COLUMNS * 16

cpdef enum State:
    TITLE
    PLAY
    GENERATE_WORLD 
    CONFIGURATION
    DEAD

state = State.TITLE

def load_texture(path, int width=18, int height=18):
    image = pygame.image.load(path).convert_alpha()
    return pygame.transform.scale(image, (width, height))

def seed_from_text(text):
    try:
        return int(text, 10) & 0xFFFFFFFF
    except ValueError:
        return int.from_bytes(hashlib.sha256(text.encode("utf-8")).digest()[:4], "big")