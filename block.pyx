import pygame

class Block(pygame.sprite.Sprite): 
    def __init__(self, texture, x, y):
        super().__init__()
        self.texture = texture
        self.rect = pygame.Rect(x, y, 16, 16)

    def __getattr__(self, name):
        if name == "x":
            return self.rect.x
        elif name == "y":
            return self.rect.y
        else:
            raise AttributeError(f"'Block' object has no attribute '{name}'")
    
    def update(self, screen, camera_x=0):
        screen.blit(self.texture, (self.rect.x - camera_x, self.rect.y))