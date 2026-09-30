/* 
 * IBM XT Font ROM
 * 
 * Steve Buer, Olympic College
 * September 2026
 */

module font_rom();

reg [7:0] font_rom [0:2047];  

/* 256 chars x 8 bytes each, for 8x8 font */

initial $readmemh("font.hex", font_rom);

wire [7:0] glyph_row = font_rom[{char_code, row_in_cell}];
