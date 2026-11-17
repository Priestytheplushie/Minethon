import pygame

class Block: 
    def __init__(self, texture, x, y):
        self.texture = texture
        self.rect = pygame.Rect(x, y, 16, 16)

    def __getattr__(self, name):
        if name == "x":
            return self.rect.x
        elif name == "y":
            return self.rect.y
        else:
            raise AttributeError(f"'Block' object has no attribute '{name}'")
    
    def update(self, screen):
        screen.blit(self.texture, self.rect) 