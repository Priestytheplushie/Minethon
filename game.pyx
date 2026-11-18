import pygame
from block import Block
import random

WIDTH = 800
HEIGHT = 600

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Minethon")
clock = pygame.time.Clock()

def load_texture(path):
    image = pygame.image.load(path).convert_alpha()
    return pygame.transform.scale(image, (16,16))

grass_tex = load_texture("assets/grass_block_side.png")
dirt_tex = load_texture("assets/dirt.png")
stone_tex = load_texture("assets/stone.png")

def generate_world():
    blocks = []
    cols = WIDTH // 16
    rows = HEIGHT // 16 + 1
    surface_y = rows // 2

    for col in range(cols):
        surface_y += random.choice([-1,0,1])
        surface_y = max(5, min(rows - 5, surface_y))
        
        for row in range(rows):
            x = col * 16
            y = row * 16
            
            if row == surface_y:
                blocks.append(Block(grass_tex, x, y))
            elif surface_y < row <= surface_y + 3:
                blocks.append(Block(dirt_tex, x, y))
            elif row > surface_y + 3:
                blocks.append(Block(stone_tex, x, y))

    return blocks

world = generate_world()

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((135, 206, 235))

    for block in world:
        block.update(screen)

    pygame.display.flip()
    clock.tick(60)