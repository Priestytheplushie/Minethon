import pygame
from block import Block
from player import Player
from noise import Noise1D, Noise2D, perlin1d, perlin2d, brownian
from random import getrandbits

WIDTH = 800
HEIGHT = 600

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Minethon")
clock = pygame.time.Clock()
cdef unsigned seed = getrandbits(32)

def load_texture(path):
    image = pygame.image.load(path).convert_alpha()
    return pygame.transform.scale(image, (16,16))

grass_tex = load_texture("assets/grass_block_side.png")
dirt_tex = load_texture("assets/dirt.png")
stone_tex = load_texture("assets/stone.png")

def generate_world():
    depth = abs(brownian(Noise1D(lambda h, x: perlin1d(h, x)), 0.7, 0.5, 10).scale(0.0625)*10) + HEIGHT / 32
    noise = brownian(Noise2D(lambda h, x, y: perlin2d(h, x, y)), 0.7, 0.5, 10).scale(0.5)*0.25 + Noise2D(lambda h, x, y: y - depth(h, x))*2**(-3)

    blocks = []
    cols = WIDTH // 16
    rows = HEIGHT // 16

    for row in range(rows+1):
        blocks.append([])
        for col in range(cols):
            val = noise(seed, col, row)
            x = col*16
            y = row*16

            if val < -0.5: blocks[row].append(None)
            elif val < 0.0:
                if row == 0 or blocks[row-1][col] == None: blocks[row].append(Block(grass_tex, x, y))
                else: blocks[row].append(Block(dirt_tex, x, y))
            else: blocks[row].append(Block(stone_tex, x, y))

    blocks_flat = []
    for row in blocks:
        for block in row:
            if block != None:
                blocks_flat.append(block)
    return blocks_flat


#def generate_world():
#    blocks = []
#    cols = WIDTH // 16
#    rows = HEIGHT // 16 + 1
#    surface_y = rows // 2
#
#    for col in range(cols):
#        surface_y += random.choice([-1,0,1])
#        surface_y = max(5, min(rows - 5, surface_y))
#
#        for row in range(rows):
#            x = col * 16
#            y = row * 16
#
#            if row == surface_y:
#                blocks.append(Block(grass_tex, x, y))
#            elif surface_y < row <= surface_y + 3:
#                blocks.append(Block(dirt_tex, x, y))
#            elif row > surface_y + 3:
#                blocks.append(Block(stone_tex, x, y))
#
#    return blocks

world = generate_world()

player = Player(WIDTH // 2, HEIGHT // 2)
all_sprites = pygame.sprite.Group(player)


while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((135, 206, 235))

    for block in world:
        block.update(screen)

    all_sprites.update(screen)

    all_sprites.draw(screen)
    pygame.display.flip()
    clock.tick(60)

pygame.quit()
