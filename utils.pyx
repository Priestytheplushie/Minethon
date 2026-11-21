import pygame
import hashlib
import random

pygame.font.init()
font = pygame.font.Font("assets/fonts/Minecraft.otf", 16)

WIDTH = 800
HEIGHT = 600
WORLD_COLUMNS = (WIDTH // 16) * 10
WORLD_WIDTH = WORLD_COLUMNS * 16

MUSIC_END = pygame.USEREVENT + 1

cpdef enum State:
    TITLE
    PLAY
    GENERATE_WORLD 
    CONFIGURATION
    DEAD

STATE_PLAYLIST = {
    State.TITLE: [
        "assets/sfx/beginning_2.ogg",
        "assets/sfx/floating_trees.ogg",
        "assets/sfx/moog_city_2.ogg",
        "assets/sfx/mutation.ogg",
    ],
    State.PLAY: [
        "assets/sfx/a_familiar_room.ogg",
        "assets/sfx/an_ordinary_day.ogg",
        "assets/sfx/ancestry.ogg",
        "assets/sfx/beginning_2.ogg",
        "assets/sfx/below_and_above.ogg",
        "assets/sfx/broken_clocks.ogg",
        "assets/sfx/bromeliad.ogg",
        "assets/sfx/clark.ogg",
        "assets/sfx/comforting_memories.ogg",
        "assets/sfx/crescent_dunes.ogg",
        "assets/sfx/danny.ogg",
        "assets/sfx/deeper.ogg",
        "assets/sfx/dry_hands.ogg",
        "assets/sfx/ebb.ogg",
        "assets/sfx/echo_in_the_wind.ogg",
        "assets/sfx/eld_unknown.ogg",
        "assets/sfx/endless.ogg",
        "assets/sfx/featherfall.ogg",
        "assets/sfx/fireflies.ogg",
        "assets/sfx/floating_dream.ogg",
        "assets/sfx/floating_trees.ogg",
        "assets/sfx/haggstrom.ogg",
        "assets/sfx/home.ogg",
        "assets/sfx/infinite_amethyst.ogg",
        "assets/sfx/key.ogg",
        "assets/sfx/komorebi.ogg",
        "assets/sfx/left_to_bloom.ogg",
        "assets/sfx/lilypad.ogg",
        "assets/sfx/living_mice.ogg",
        "assets/sfx/memories.ogg",
        "assets/sfx/mice_on_venus.ogg",
        "assets/sfx/minecraft.ogg",
        "assets/sfx/moog_city_2.ogg",
        "assets/sfx/mutation.ogg",
        "assets/sfx/nightly.ogg",
        "assets/sfx/one_more_day.ogg",
        "assets/sfx/os_piano.ogg",
        "assets/sfx/oxygene.ogg",
        "assets/sfx/pokopoko.ogg",
        "assets/sfx/puzzlebox.ogg",
        "assets/sfx/shores.ogg",
        "assets/sfx/stand_tall.ogg",
        "assets/sfx/subwoofer_lullaby.ogg",
        "assets/sfx/sweden.ogg",
        "assets/sfx/watcher.ogg",
        "assets/sfx/wending.ogg",
        "assets/sfx/wet_hands.ogg",
        "assets/sfx/yakusoku.ogg",
    ],
}

current_track = None

state = State.TITLE

def load_texture(path, int width=18, int height=18):
    image = pygame.image.load(path).convert_alpha()
    return pygame.transform.scale(image, (width, height))

def seed_from_text(text):
    try:
        return int(text, 10) & 0xFFFFFFFF
    except ValueError:
        return int.from_bytes(hashlib.sha256(text.encode("utf-8")).digest()[:4], "big")

def play_random_track(state):
    global current_track
    playlist = STATE_PLAYLIST.get(state, [])
    choices = [track for track in playlist if track]
    if not choices:
        return
    if pygame.mixer.get_init() is None:
        pygame.mixer.init()
    selectable_tracks = (
        [track for track in choices if track != current_track]
        if len(choices) > 1
        else choices
    )
    next_track = random.choice(selectable_tracks)
    pygame.mixer.music.load(next_track)
    pygame.mixer.music.set_volume(0.4)
    pygame.mixer.music.play(
        loops=0, fade_ms=1000
    )
    current_track = next_track
