import pygame
from block import Block
from player import Player
from utils import load_texture
from noise import Noise1D, Noise2D, perlin1d, perlin2d, brownian
from random import getrandbits

WIDTH = 800
HEIGHT = 600
WORLD_COLUMNS = (WIDTH // 16) * 10
WORLD_WIDTH = WORLD_COLUMNS * 16

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Minethon")
clock = pygame.time.Clock()
cdef unsigned seed = getrandbits(32)

grass_tex = load_texture("assets/grass_block_side.png",16,16)
dirt_tex = load_texture("assets/dirt.png",16,16)
stone_tex = load_texture("assets/stone.png",16,16)

def generate_world():
    depth = abs(brownian(Noise1D(lambda h, x: perlin1d(h, x)), 0.7, 0.5, 10).scale(0.0625)*10) + HEIGHT / 32
    noise = brownian(Noise2D(lambda h, x, y: perlin2d(h, x, y)), 0.7, 0.5, 10).scale(0.5)*0.25 + Noise2D(lambda h, x, y: y - depth(h, x))*2**(-3)

    blocks = []
    cols = WORLD_COLUMNS
    rows = HEIGHT // 16 + 1
    surface_y = rows // 2

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

spawn_column = (WORLD_WIDTH // 2 // 16) * 16
blocks_in_spawn_column = [
    block for block in world
    if block.rect.left == spawn_column
]
spawn_block = min(
    blocks_in_spawn_column,
    key=lambda block: block.rect.top,
)
player = Player(spawn_block.rect.centerx, 0)
player.rect.midbottom = (spawn_block.rect.centerx, spawn_block.rect.top)
all_sprites = pygame.sprite.Group(player)
block_group = pygame.sprite.Group(*world)


while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((135, 206, 235))

    all_sprites.update(screen, block_group, WORLD_WIDTH)
    camera_x = max(
        0,
        min(player.rect.centerx - WIDTH // 2, WORLD_WIDTH - WIDTH),
    )

    for block in world:
        if block.rect.right > camera_x and block.rect.left < camera_x + WIDTH:
            block.update(screen, camera_x)

    screen.blit(player.image, (player.rect.x - camera_x, player.rect.y))
    player.draw_hearts(screen)
    pygame.display.flip()
    clock.tick(60)

pygame.quit()
