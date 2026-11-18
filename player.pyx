import pygame

def load_texture(path):
    image = pygame.image.load(path).convert_alpha()
    return pygame.transform.scale_by(image, 14.0 / image.get_rect().width)

class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = load_texture("assets/steve.png")
        self.rect = self.image.get_rect(center=(x, y))
        self.speed = 5

    def update(self,screen):
        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT] or keys[pygame.K_a]:
            self.rect.x -= self.speed
        if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
            self.rect.x += self.speed
        if keys[pygame.K_UP] or keys[pygame.K_w]:
            self.rect.y -= self.speed
        if keys[pygame.K_DOWN] or keys[pygame.K_s]:
            self.rect.y += self.speed

        self.rect.clamp_ip(screen.get_rect())

    