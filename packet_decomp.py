
import serial
from enum import Enum
import numpy as np
import cv2


####################
# 
# |  ID  | Ycoord | Xcoord |   Misc   |  Value  |  Amount  |
# 
# |   Misc   | = |    RLE MSBs    | Channel Type | Ycoord LSB | Xcoord LSB | 
#    8 bits            4 bits          2 bits        1 bit         1 bit  
#
# 1) Read the ID of the packet. 
#   - If it is not prev_id + 1, keep reading until it is prev_id + 2.
# 2) Read the first frame of the Y coordinate of the pixel.
# 3) Read the first frame of the X coordinate of the pixel.
# 4) Read the Misc value and decompose it into miscellaneous info.
# 5) Read the value of the pixel.
# 6) Read the amount of pixels to be filled with the value.
####################


class PackFrame(Enum) :
    ID = 0
    YCOORD = 1
    XCOORD = 2
    MISC = 3
    VALUE = 4
    AMOUNT = 5

PACKET_LEN = 6
FRAME_WIDTH = 512
FRAME_HEIGHT = 384

curr_frame = {
    0 : np.zeros((FRAME_HEIGHT, FRAME_WIDTH)),
    1 : np.zeros((FRAME_HEIGHT/2, FRAME_WIDTH)),
    2 : np.zeros((FRAME_HEIGHT/2, FRAME_WIDTH))
}

next_frame = {
    0 : np.zeros((FRAME_HEIGHT, FRAME_WIDTH)),
    1 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH)),
    2 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH))
}

curr_packet_id = 0
curr_frame_idx = 0

y_coord = None
x_coord = None
ch_type = None
value   = None
amount  = None

def match_frame(data : int) :
    global curr_frame_idx, y_coord, x_coord, ch_type, value, amount
    match curr_frame_idx :
        case PackFrame.ID :
            if data != curr_packet_id + 1:
                print(f"Transmission error - a packet with id {data} when current id is {curr_packet_id}")
                exit(0)
            curr_packet_id = data % 256
        case PackFrame.YCOORD :
            y_coord = data << 1
        case PackFrame.XCOORD :
            x_coord = data << 1
        case PackFrame.MISC :
            amount = int(data & 0b1111) << 8
            ch_type = (data >> 4) & 0b11
            y_coord |= (data >> 6) & 0b1
            x_coord |= (data >> 7) & 0b1
        case PackFrame.VALUE :
            value = data
        case PackFrame.AMOUNT :
            amount += data
        case _ :
            print("Invalid packet index")
    curr_frame_idx += 1


with serial.Serial("COM4", 3_000_000, 8, "N") as receiver :
    while True :
        frame = receiver.read(1)
        if len(frame) == 0 :
            continue
        match_frame(frame[0])
        if curr_frame_idx == PACKET_LEN: # read the info, start redrawing
            next_frame[ch_type][y_coord][x_coord:x_coord + amount] = value
            curr_frame_idx = 0
