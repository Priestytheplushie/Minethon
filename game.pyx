import pygame
from block import Block

pygame.init()
screen = pygame.display.set_mode((800, 600))
pygame.display.set_caption("Minethon")

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((0, 0, 0))
    grass_block.update(screen)
    pygame.display.flip()