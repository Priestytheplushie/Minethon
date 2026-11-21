import pygame
pygame.init()
from utils import WIDTH, HEIGHT, WORLD_COLUMNS, WORLD_WIDTH, WORLD_ROWS, State, state, font, seed_from_text
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Minethon")
clock = pygame.time.Clock()
pygame.mixer.music.set_endevent(MUSIC_END)
play_random_track(State.TITLE)
cdef unsigned seed = 0

from items import ItemType, BlockType, Item, item_assets, block_assets, item_placed, block_drop, get_item_asset, is_solid_block
from player import Player
from utils import load_texture
from noise import Noise1D, Noise2D, perlin1d, perlin2d, brownian
from random import choice, getrandbits
from widgets import Button, TextInput
from splashes import SPLASH_TEXT

cdef unsigned seed = 0

def generate_world():
    depth = abs(brownian(Noise1D(lambda h, x: perlin1d(h, x)), 0.7, 0.5, 10).scale(0.0625)*10) + HEIGHT / 32
    noise = brownian(Noise2D(lambda h, x, y: perlin2d(h, x, y)), 0.7, 0.5, 10).scale(0.5)*0.25 + Noise2D(lambda h, x, y: y - depth(h, x))*2**(-3)

    blocks = []
    cols = WORLD_COLUMNS
    rows = WORLD_ROWS
    surface_y = rows // 2

    for row in range(rows):
        blocks.append([])
        for col in range(cols):
            val = noise(seed, col, row)
            x = col*16
            y = row*16

            if val < -0.5: blocks[row].append(BlockType.AIR)
            elif val < 0.0:
                if row == 0 or blocks[row-1][col] == BlockType.AIR: blocks[row].append(BlockType.GRASS)
                else: blocks[row].append(BlockType.DIRT)
            else: blocks[row].append(BlockType.STONE)
    return blocks

# Menu Assets
raw_normal = pygame.image.load("assets/button.png").convert_alpha()
raw_hover = pygame.image.load("assets/button_highlighted.png").convert_alpha()
create_world_button = Button(200, 360, "Create New World", raw_normal, raw_hover, scale=2)
seed_input = TextInput(400, 290, width=500, height=40, placeholder="Leave blank for a random seed")
seed_label = font.render("Seed for the World Generator", False, (255, 255, 255))
seed_label_shadow = font.render("Seed for the World Generator", False, (56, 56, 56))
seed_label_rect = seed_label.get_rect(center=(seed_input.rect.centerx, 250))
seed_label_shadow_rect = seed_label_shadow.get_rect(center=(seed_label_rect.centerx + 2, seed_label_rect.centery + 2))

logo_width = seed_input.rect.width

title_logo = pygame.image.load("assets/minethon.png").convert_alpha()
logo_height = round(title_logo.get_height() * logo_width / title_logo.get_width())
title_logo = pygame.transform.smoothscale(title_logo, (logo_width, logo_height))
title_logo_rect = title_logo.get_rect(midbottom=(seed_input.rect.centerx, seed_label_rect.top - 50))
splash_message = choice(SPLASH_TEXT)
splash_font = pygame.font.Font("assets/fonts/Minecraft.otf", 22)
splash_text = splash_font.render(splash_message, False, (255, 255, 0))
splash_shadow = splash_font.render(splash_message, False, (56, 56, 0))
splash_text = pygame.transform.rotate(splash_text, 20)
splash_shadow = pygame.transform.rotate(splash_shadow, 20)
splash_rect = splash_text.get_rect(
    center=(
        title_logo_rect.right,
        title_logo_rect.centery + title_logo_rect.height // 8,
    )
)

faces = [
    pygame.transform.scale(pygame.image.load(f"assets/panorama_{i}.png").convert(), (HEIGHT, HEIGHT))
    for i in range(4) ]
pano_width = HEIGHT * 4
panorama = pygame.Surface((pano_width, HEIGHT))
for i, face in enumerate(faces):
    panorama.blit(face, (i * HEIGHT, 0))
scroll_x = 0
scroll_speed = 60

minethon_version_label = font.render("Minethon 0.1.0-alpha",False,(255, 255, 255))
minethon_version_shadow = font.render("Minethon 0.1.0-alpha", False, (56, 56, 56))

while True:
    dt = clock.tick(60) / 1000
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()
        elif event.type == MUSIC_END:
            play_random_track(state)
        if state == State.TITLE:
            seed_input.handle_event(event)
            if create_world_button.is_clicked(event):
                create_world_button.sfx.play()
                if seed_input.text:
                    seed = seed_from_text(seed_input.text)
                else:
                    seed = getrandbits(32)
                world = generate_world()
                spawn_column = WORLD_COLUMNS // 2
                blocks_in_spawn_column = list(map(lambda row: row[spawn_column], world))
                spawn_block = 0
                while not is_solid_block.get(blocks_in_spawn_column[spawn_block], False):
                    spawn_block += 1
                player = Player((spawn_column + 0.5)*16, 0)
                player.rect.midbottom = ((spawn_column + 0.5)*16, spawn_block*16 - 1.0)
                all_sprites = pygame.sprite.Group(player)
                state = State.PLAY
                play_random_track(state)

    match state:
        case State.TITLE:
            scroll_x = (scroll_x - scroll_speed * dt) % pano_width
            screen.blit(panorama, (scroll_x - pano_width, 0))
            screen.blit(panorama, (scroll_x, 0))
            screen.blit(title_logo, title_logo_rect)
            screen.blit(splash_shadow, splash_rect.move(2, 2))
            screen.blit(splash_text, splash_rect)
            create_world_button.draw(screen)
            screen.blit(seed_label_shadow, seed_label_shadow_rect)
            screen.blit(seed_label, seed_label_rect)
            screen.blit(minethon_version_shadow, (7, HEIGHT - 18))
            screen.blit(minethon_version_label, (5, HEIGHT - 20))
            seed_input.draw(screen)
            pygame.display.flip()

        case State.PLAY:
            screen.fill((135, 206, 235))

            all_sprites.update(screen, world, WORLD_WIDTH)
            camera_x = max(
                0,
                min(player.rect.centerx - WIDTH // 2, WORLD_WIDTH - WIDTH),
            )

            for i in range(camera_x // 16 - 1, (camera_x + WIDTH) // 16 + 1):
                for j in range(0, WORLD_ROWS):
                    block = world[j][i%WORLD_COLUMNS]
                    img = block_assets.get(block, None)
                    if img == None: continue
                    screen.blit(img, (i * 16 - camera_x, j * 16))

            screen.blit(player.image, (player.rect.x - camera_x, player.rect.y))
            player.draw_hearts(screen)
            pygame.display.flip()
        case _:
            break

pygame.quit()
