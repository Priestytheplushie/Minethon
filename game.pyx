import pygame
pygame.init()
from utils import WIDTH, HEIGHT, WORLD_COLUMNS, WORLD_WIDTH, WORLD_ROWS, State, state, font, seed_from_text, MUSIC_END, play_random_track
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Minethon")
clock = pygame.time.Clock()
pygame.mixer.music.set_endevent(MUSIC_END)
play_random_track(State.TITLE)

from items import ItemType, BlockType, Item, item_assets, block_assets, item_placed, block_drop, get_item_asset, is_solid_block
from player import Player
from utils import load_texture
from noise import Noise1D, Noise2D, perlin1d, perlin2d, brownian
from random import choice, getrandbits, random, seed as set_random_seed
from widgets import Button, TextInput
from splashes import SPLASH_TEXT

BLOCK_NAMES = {
    BlockType.DIRT: "Dirt",
    BlockType.COBBLESTONE: "Cobblestone",
    BlockType.OAK_LOG: "Oak Log",
    BlockType.OAK_LEAVES: "Oak Leaves",
    BlockType.STONE: "Stone",
    BlockType.GRASS: "Grass Block",
    BlockType.OAK_PLANKS: "Oak Planks",
}

cdef unsigned seed = 0

def plant_tree(blocks, int col, int ground_row):
    cdef int trunk_height = 5
    cdef int trunk_top = ground_row - trunk_height
    cdef int leaf_row, leaf_col, dx, r
    blocks[ground_row][col] = BlockType.DIRT
    for r in range(trunk_top + 1, trunk_top + 3):
        for dx in range(-2, 3):
            leaf_col = col + dx
            if blocks[r][leaf_col] == BlockType.AIR:
                if abs(dx) == 2 and (r == trunk_top + 1 and random() < 0.5):
                    continue
                blocks[r][leaf_col] = BlockType.OAK_LEAVES
    for dx in range(-1, 2):
        leaf_col = col + dx
        if blocks[trunk_top][leaf_col] == BlockType.AIR:
            blocks[trunk_top][leaf_col] = BlockType.OAK_LEAVES
    for dx in range(-1, 2):
        leaf_col = col + dx
        if abs(dx) == 0 or random() < 0.5:
            if blocks[trunk_top - 1][leaf_col] == BlockType.AIR:
                blocks[trunk_top - 1][leaf_col] = BlockType.OAK_LEAVES
    for r in range(trunk_top, ground_row):
        blocks[r][col] = BlockType.OAK_LOG

def generate_world():
    set_random_seed(seed)
    depth = abs(brownian(Noise1D(lambda h, x: perlin1d(h, x)), 0.7, 0.5, 10).scale(0.0625)*10) + HEIGHT / 32
    noise = brownian(Noise2D(lambda h, x, y: perlin2d(h, x, y)), 0.7, 0.5, 10).scale(0.5)*0.25 + Noise2D(lambda h, x, y: y - depth(h, x))*2**(-3)
    blocks = []
    cols = WORLD_COLUMNS
    rows = WORLD_ROWS
    for row in range(rows):
        blocks.append([])
        for col in range(cols):
            val = noise(seed, col, row)
            if val < -0.5:
                blocks[row].append(BlockType.AIR)
            elif val < 0.0:
                if row == 0 or blocks[row-1][col] == BlockType.AIR:
                    blocks[row].append(BlockType.GRASS)
                else:
                    blocks[row].append(BlockType.DIRT)
            else:
                blocks[row].append(BlockType.STONE)
    cdef int last_tree_col = -999
    cdef int ground_row, r
    cdef bint has_clearance

    for col in range(2, cols - 2):
        if col - last_tree_col < 8:
            continue
        ground_row = -1
        for r in range(rows):
            if blocks[r][col] != BlockType.AIR:
                ground_row = r
                break
        if ground_row == -1 or blocks[ground_row][col] != BlockType.GRASS:
            continue
        if ground_row < 7:
            continue
        has_clearance = True
        for r in range(ground_row - 6, ground_row):
            if blocks[r][col] != BlockType.AIR:
                has_clearance = False
                break
        if not has_clearance:
            continue
        if random() < 0.10:
            plant_tree(blocks, col, ground_row)
            last_tree_col = col
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
camera_x = 0

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
        if state == State.PLAY:
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    player.selected_block = BlockType.DIRT
                elif event.key == pygame.K_2:
                    player.selected_block = BlockType.COBBLESTONE
                elif event.key == pygame.K_3:
                    player.selected_block = BlockType.OAK_LOG
                elif event.key == pygame.K_4:
                    player.selected_block = BlockType.OAK_LEAVES
                elif event.key == pygame.K_5:
                    player.selected_block = BlockType.STONE
                elif event.key == pygame.K_6:
                    player.selected_block = BlockType.GRASS
                elif event.key == pygame.K_7:
                    player.selected_block = BlockType.OAK_PLANKS
            elif event.type == pygame.MOUSEBUTTONDOWN:
                mouse_x, mouse_y = event.pos
                target_col = (mouse_x + camera_x) // 16
                target_row = mouse_y // 16
                if 0 <= target_col < WORLD_COLUMNS and 0 <= target_row < WORLD_ROWS:
                    block_center_x = target_col * 16 + 8
                    block_center_y = target_row * 16 + 8
                    dist_sq = (player.rect.centerx - block_center_x) ** 2 + (player.rect.centery - block_center_y) ** 2
                    if dist_sq <= 6400:
                        # Left Click
                        if event.button == 1:
                            if world[target_row][target_col] != BlockType.AIR:
                                world[target_row][target_col] = BlockType.AIR
                        # Right Click
                        elif event.button == 3:
                            if world[target_row][target_col] == BlockType.AIR:
                                block_rect = pygame.Rect(target_col * 16, target_row * 16, 16, 16)
                                if not player.rect.colliderect(block_rect):
                                    world[target_row][target_col] = player.selected_block


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
                    block = world[j][i % WORLD_COLUMNS]
                    img = block_assets.get(block, None)
                    if img is None: continue
                    screen.blit(img, (i * 16 - camera_x, j * 16))
            mouse_x, mouse_y = pygame.mouse.get_pos()
            hover_col = (mouse_x + camera_x) // 16
            hover_row = mouse_y // 16

            if 0 <= hover_col < WORLD_COLUMNS and 0 <= hover_row < WORLD_ROWS:
                block_center_x = hover_col * 16 + 8
                block_center_y = hover_row * 16 + 8
                dist_sq = (player.rect.centerx - block_center_x) ** 2 + (player.rect.centery - block_center_y) ** 2
                if dist_sq <= 6400:
                    highlight_rect = pygame.Rect(hover_col * 16 - camera_x, hover_row * 16, 16, 16)
                    pygame.draw.rect(screen, (0, 0, 0), highlight_rect, 1)
            screen.blit(player.image, (player.rect.x - camera_x, player.rect.y))
            player.draw_hearts(screen)
            held_name = BLOCK_NAMES.get(player.selected_block, "Unknown")
            hud_text = font.render(f"Hand: {held_name} (Keys 1-7)", False, (255, 255, 255))
            hud_shadow = font.render(f"Hand: {held_name} (Keys 1-7)", False, (56, 56, 56))
            screen.blit(hud_shadow, (WIDTH - hud_text.get_width() - 8, 12))
            screen.blit(hud_text, (WIDTH - hud_text.get_width() - 10, 10))

            pygame.display.flip()
        case _:
            break

pygame.quit()
