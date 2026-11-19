import pygame

def load_texture(path, int width=18, int height=18):
    image = pygame.image.load(path).convert_alpha()
    return pygame.transform.scale(image, (width, height))