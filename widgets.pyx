import sys 
import pygame
from utils import font

class Button:
    def __init__(self, x, y, text, normal_img, hover_img, scale=2):
        width = normal_img.get_width() * scale
        height = normal_img.get_height() * scale
        self.rect = pygame.Rect(x, y, width, height)
        self.normal_surf = pygame.transform.scale(normal_img, (width, height))
        self.hover_surf = pygame.transform.scale(hover_img, (width, height))
        self.text_surf = font.render(text, False, (255, 255, 255))
        self.hover_text_surf = font.render(text, False, (255, 255, 160))
        self.shadow_surf = font.render(text, False, (56, 56, 56))
        self.sfx = pygame.mixer.Sound("assets/sfx/click.mp3")
        self.text_rect = self.text_surf.get_rect(center=self.rect.center)
        self.shadow_rect = self.shadow_surf.get_rect(
            center=(self.rect.centerx + 2, self.rect.centery + 2)
        )

    def draw(self, surface):
        is_hovered = self.rect.collidepoint(pygame.mouse.get_pos())
        surface.blit(
            self.hover_surf if is_hovered else self.normal_surf, self.rect
        )
        surface.blit(self.shadow_surf, self.shadow_rect)
        surface.blit(
            self.hover_text_surf if is_hovered else self.text_surf,
            self.text_rect,
        )

    def is_clicked(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            return self.rect.collidepoint(event.pos)
        return False

class TextInput:
    def __init__(
        self, center_x, center_y, width=400, height=40, max_chars=32,
        placeholder="",
    ):
        self.rect = pygame.Rect(0, 0, width, height)
        self.rect.center = (center_x, center_y)
        self.text = ""
        self.placeholder = placeholder
        self.max_chars = max_chars
        self.active = False
        self.bg_color = (0, 0, 0)
        self.border_inactive = (160, 160, 160)
        self.border_active = (255, 255, 255)
        self.text_color = (224, 224, 224)
        self.placeholder_color = (128, 128, 128)
        self.shadow_color = (56, 56, 56)

    def handle_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self.active = self.rect.collidepoint(event.pos)
        if event.type == pygame.KEYDOWN and self.active:
            if event.key == pygame.K_BACKSPACE:
                self.text = self.text[:-1]
            elif event.key == pygame.K_RETURN:
                self.active = False
            elif len(self.text) < self.max_chars and event.unicode.isprintable():
                self.text += event.unicode

    def draw(self, surface):
        border_color = (
            self.border_active if self.active else self.border_inactive
        )
        pygame.draw.rect(surface, self.bg_color, self.rect)
        pygame.draw.rect(surface, border_color, self.rect, width=2)
        show_cursor = self.active and (pygame.time.get_ticks() // 500) % 2 == 0
        is_placeholder = not self.text and bool(self.placeholder)
        display_text = (
            self.placeholder
            if is_placeholder
            else self.text + ("_" if show_cursor else "")
        )
        shadow_surf = font.render(display_text, False, self.shadow_color)
        text_color = (
            self.placeholder_color if is_placeholder else self.text_color
        )
        text_surf = font.render(display_text, False, text_color)
        text_y = self.rect.centery - text_surf.get_height() // 2
        text_x = self.rect.x + 10
        surface.blit(shadow_surf, (text_x + 2, text_y + 2))
        surface.blit(text_surf, (text_x, text_y))