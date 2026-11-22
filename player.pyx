import pygame
from items import is_solid_block, BlockType
from utils import load_texture, WORLD_COLUMNS, WORLD_ROWS
from items import is_solid_block, is_semisolid_block, BlockType

class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.selected_block = BlockType.DIRT
        self.image = load_texture("assets/steve.png", 18, 36)
        self.rect = self.image.get_rect(center=(x, y))
        self.speed = 1.8  
        self.gravity = 0.45
        self.max_fall_speed = 10
        self.velocity_y = 0
        self.on_ground = False
        self.hp = 20
        self.max_hp = 20
        self.armor = 0
        self.jump_velocity = -5.4
        self.hunger = 20

        self.full_heart = load_texture("assets/full.png")
        self.empty_heart = load_texture("assets/container.png")
        self.half_heart = load_texture("assets/half.png")

    def draw_hearts(self, screen):
        cdef int i
        cdef int spacing = 16
        cdef int start_x = 10
        cdef int start_y = 10
        cdef int x
        cdef int hp = self.hp

        for i in range(10):
            x = start_x + i * spacing
            screen.blit(self.empty_heart, (x, start_y))

            if hp >= (i + 1) * 2:
                screen.blit(self.full_heart, (x, start_y))
            elif hp == (i * 2) + 1:
                screen.blit(self.half_heart, (x, start_y))

    def take_damage(self, int amount):
        if amount <= 0 or self.hp <= 0:
            return
        self.hp -= amount
        if self.hp < 0:
            self.hp = 0

    def heal(self, int amount):
        if amount <= 0 or self.hp <= 0:
            return
        self.hp += amount
        if self.hp > self.max_hp:
            self.hp = self.max_hp

    def update(self, screen, blocks, world_width=None):
        keys = pygame.key.get_pressed()
        dx = 0
        if keys[pygame.K_LEFT] or keys[pygame.K_a]:
            dx -= self.speed
        if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
            dx += self.speed

        self.rect.x += round(dx)
        self.rect.left = max(0, self.rect.left)
        if world_width is None:
            world_width = screen.get_width()
        self.rect.right = min(world_width, self.rect.right)

        horizontal_hits = self.collide(blocks)
        if dx > 0 and horizontal_hits:
            self.rect.right = min(x for (x, y) in horizontal_hits)
        elif dx < 0 and horizontal_hits:
            self.rect.left = max(x + 16 for (x, y) in horizontal_hits)

        if (
            self.on_ground
            and (keys[pygame.K_SPACE] or keys[pygame.K_UP] or keys[pygame.K_w])
        ):
            self.velocity_y = getattr(self, "jump_velocity", -5.4)
            self.on_ground = False

        cdef int prev_bottom = self.rect.bottom

        self.velocity_y = min(
            self.velocity_y + self.gravity, self.max_fall_speed
        )
        self.rect.y += round(self.velocity_y)

        vertical_hits = self.collide(blocks)
        self.on_ground = False

        if vertical_hits and self.velocity_y > 0:
            self.rect.bottom = min(y for (x, y) in vertical_hits)
            self.on_ground = True
            self.velocity_y = 0
        elif vertical_hits and self.velocity_y < 0:
            self.rect.top = max(y + 16 for (x, y) in vertical_hits)
            self.velocity_y = 0

        if (
            not self.on_ground
            and self.velocity_y > 0
            and not (keys[pygame.K_DOWN] or keys[pygame.K_s])
        ):
            semisolid_hits = self.collide_semisolid(blocks)
            valid_lands = []
            for box in semisolid_hits:
                if prev_bottom <= box.top + 2:
                    valid_lands.append(box.top)

            if valid_lands:
                self.rect.bottom = min(valid_lands)
                self.on_ground = True
                self.velocity_y = 0

    def collide(self, blocks):
        hits = []
        for i in range(int(self.rect.centerx // 16) - 1, int(self.rect.centerx // 16) + 2):
            for j in range(int(self.rect.centery // 16) - 2, int(self.rect.centery // 16) + 3):
                if is_solid_block.get(blocks[j%WORLD_ROWS][i%WORLD_COLUMNS], False):
                    box = pygame.Rect(i*16, j*16, 16, 16)
                    if box.colliderect(self.rect):
                        hits.append((i*16, j*16))
        return hits

    def collide_semisolid(self, blocks):
        hits = []
        for i in range(int(self.rect.centerx // 16) - 1, int(self.rect.centerx // 16) + 2):
            for j in range(int(self.rect.centery // 16) - 2, int(self.rect.centery // 16) + 3):
                if is_semisolid_block.get(blocks[j % WORLD_ROWS][i % WORLD_COLUMNS], False):
                    box = pygame.Rect(i * 16, j * 16, 16, 16)
                    if box.colliderect(self.rect):
                        hits.append(box)
        return hits