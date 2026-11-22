# distutils: language = c++
from utils import load_texture
from libc.stdint cimport uint8_t

cpdef enum class BlockType:
    AIR, GRASS, DIRT, STONE, COBBLESTONE

cpdef enum class ItemType:
    DIRT, COBBLESTONE

item_placed = {
	ItemType.DIRT: BlockType.DIRT,
	ItemType.COBBLESTONE: BlockType.COBBLESTONE,
}

block_drop = {
	BlockType.GRASS: ItemType.DIRT,
	BlockType.DIRT: ItemType.DIRT,
	BlockType.STONE: ItemType.COBBLESTONE,
	BlockType.COBBLESTONE: ItemType.COBBLESTONE,
}

block_assets = {
    BlockType.GRASS: load_texture("assets/grass_block_side.png"),
    BlockType.DIRT: load_texture("assets/dirt.png"),
    BlockType.STONE: load_texture("assets/stone.png"),
}

is_solid_block = {
    BlockType.AIR: False,
    BlockType.GRASS: True,
    BlockType.DIRT: True,
    BlockType.STONE: True,
    BlockType.COBBLESTONE: True,
}

item_assets = dict()

def get_item_asset(item):
    ia = item_assets.get(item, None)
    if ia != None: return ia
    block = item_placed.get(item, None)
    if block != None:
        ba = block_assets.get(block, None)
        if ba != None: return ba
    return None

cdef class Item:
    cdef ItemType type
    cdef uint8_t count
    def __init__(self, ItemType type, unsigned count = 1):
        self.type = type
        self.count = count
