// 8x8 pixel bitmap font ROM for ASCII 0x20-0x7F.
// Bit 7 of pixels = leftmost pixel; bit 0 = rightmost. Row 0 = top, row 7 = bottom.
// Combinational read (always @(*)) -- no pipeline delay, inferred as LUTs.
`default_nettype none

module font_rom (
    input  wire [7:0] char_code,
    input  wire [2:0] row,
    output reg  [7:0] pixels
);
    always @(*) begin
        case ({char_code, row})

            // 0x20 ' '
            {8'h20,3'd0}: pixels=8'h00; {8'h20,3'd1}: pixels=8'h00;
            {8'h20,3'd2}: pixels=8'h00; {8'h20,3'd3}: pixels=8'h00;
            {8'h20,3'd4}: pixels=8'h00; {8'h20,3'd5}: pixels=8'h00;
            {8'h20,3'd6}: pixels=8'h00; {8'h20,3'd7}: pixels=8'h00;

            // 0x21 '!'
            {8'h21,3'd0}: pixels=8'h18; {8'h21,3'd1}: pixels=8'h3C;
            {8'h21,3'd2}: pixels=8'h3C; {8'h21,3'd3}: pixels=8'h18;
            {8'h21,3'd4}: pixels=8'h18; {8'h21,3'd5}: pixels=8'h00;
            {8'h21,3'd6}: pixels=8'h18; {8'h21,3'd7}: pixels=8'h00;

            // 0x22 '"'
            {8'h22,3'd0}: pixels=8'h66; {8'h22,3'd1}: pixels=8'h66;
            {8'h22,3'd2}: pixels=8'h24; {8'h22,3'd3}: pixels=8'h00;
            {8'h22,3'd4}: pixels=8'h00; {8'h22,3'd5}: pixels=8'h00;
            {8'h22,3'd6}: pixels=8'h00; {8'h22,3'd7}: pixels=8'h00;

            // 0x23 '#'
            {8'h23,3'd0}: pixels=8'h6C; {8'h23,3'd1}: pixels=8'h6C;
            {8'h23,3'd2}: pixels=8'hFE; {8'h23,3'd3}: pixels=8'h6C;
            {8'h23,3'd4}: pixels=8'hFE; {8'h23,3'd5}: pixels=8'h6C;
            {8'h23,3'd6}: pixels=8'h6C; {8'h23,3'd7}: pixels=8'h00;

            // 0x24 '$'
            {8'h24,3'd0}: pixels=8'h18; {8'h24,3'd1}: pixels=8'h3E;
            {8'h24,3'd2}: pixels=8'h58; {8'h24,3'd3}: pixels=8'h3C;
            {8'h24,3'd4}: pixels=8'h1A; {8'h24,3'd5}: pixels=8'h3C;
            {8'h24,3'd6}: pixels=8'h18; {8'h24,3'd7}: pixels=8'h00;

            // 0x25 '%'
            {8'h25,3'd0}: pixels=8'h00; {8'h25,3'd1}: pixels=8'hC6;
            {8'h25,3'd2}: pixels=8'hCC; {8'h25,3'd3}: pixels=8'h18;
            {8'h25,3'd4}: pixels=8'h30; {8'h25,3'd5}: pixels=8'h66;
            {8'h25,3'd6}: pixels=8'hC6; {8'h25,3'd7}: pixels=8'h00;

            // 0x26 '&'
            {8'h26,3'd0}: pixels=8'h38; {8'h26,3'd1}: pixels=8'h6C;
            {8'h26,3'd2}: pixels=8'h38; {8'h26,3'd3}: pixels=8'h76;
            {8'h26,3'd4}: pixels=8'hDC; {8'h26,3'd5}: pixels=8'hCC;
            {8'h26,3'd6}: pixels=8'h76; {8'h26,3'd7}: pixels=8'h00;

            // 0x27 '\''
            {8'h27,3'd0}: pixels=8'h18; {8'h27,3'd1}: pixels=8'h18;
            {8'h27,3'd2}: pixels=8'h30; {8'h27,3'd3}: pixels=8'h00;
            {8'h27,3'd4}: pixels=8'h00; {8'h27,3'd5}: pixels=8'h00;
            {8'h27,3'd6}: pixels=8'h00; {8'h27,3'd7}: pixels=8'h00;

            // 0x28 '('
            {8'h28,3'd0}: pixels=8'h0E; {8'h28,3'd1}: pixels=8'h1C;
            {8'h28,3'd2}: pixels=8'h38; {8'h28,3'd3}: pixels=8'h38;
            {8'h28,3'd4}: pixels=8'h38; {8'h28,3'd5}: pixels=8'h1C;
            {8'h28,3'd6}: pixels=8'h0E; {8'h28,3'd7}: pixels=8'h00;

            // 0x29 ')'
            {8'h29,3'd0}: pixels=8'h70; {8'h29,3'd1}: pixels=8'h38;
            {8'h29,3'd2}: pixels=8'h1C; {8'h29,3'd3}: pixels=8'h1C;
            {8'h29,3'd4}: pixels=8'h1C; {8'h29,3'd5}: pixels=8'h38;
            {8'h29,3'd6}: pixels=8'h70; {8'h29,3'd7}: pixels=8'h00;

            // 0x2A '*'
            {8'h2A,3'd0}: pixels=8'h00; {8'h2A,3'd1}: pixels=8'h66;
            {8'h2A,3'd2}: pixels=8'h3C; {8'h2A,3'd3}: pixels=8'hFF;
            {8'h2A,3'd4}: pixels=8'h3C; {8'h2A,3'd5}: pixels=8'h66;
            {8'h2A,3'd6}: pixels=8'h00; {8'h2A,3'd7}: pixels=8'h00;

            // 0x2B '+'
            {8'h2B,3'd0}: pixels=8'h00; {8'h2B,3'd1}: pixels=8'h18;
            {8'h2B,3'd2}: pixels=8'h18; {8'h2B,3'd3}: pixels=8'h7E;
            {8'h2B,3'd4}: pixels=8'h18; {8'h2B,3'd5}: pixels=8'h18;
            {8'h2B,3'd6}: pixels=8'h00; {8'h2B,3'd7}: pixels=8'h00;

            // 0x2C ','
            {8'h2C,3'd0}: pixels=8'h00; {8'h2C,3'd1}: pixels=8'h00;
            {8'h2C,3'd2}: pixels=8'h00; {8'h2C,3'd3}: pixels=8'h00;
            {8'h2C,3'd4}: pixels=8'h18; {8'h2C,3'd5}: pixels=8'h18;
            {8'h2C,3'd6}: pixels=8'h30; {8'h2C,3'd7}: pixels=8'h00;

            // 0x2D '-'
            {8'h2D,3'd0}: pixels=8'h00; {8'h2D,3'd1}: pixels=8'h00;
            {8'h2D,3'd2}: pixels=8'h00; {8'h2D,3'd3}: pixels=8'h7E;
            {8'h2D,3'd4}: pixels=8'h00; {8'h2D,3'd5}: pixels=8'h00;
            {8'h2D,3'd6}: pixels=8'h00; {8'h2D,3'd7}: pixels=8'h00;

            // 0x2E '.'
            {8'h2E,3'd0}: pixels=8'h00; {8'h2E,3'd1}: pixels=8'h00;
            {8'h2E,3'd2}: pixels=8'h00; {8'h2E,3'd3}: pixels=8'h00;
            {8'h2E,3'd4}: pixels=8'h00; {8'h2E,3'd5}: pixels=8'h18;
            {8'h2E,3'd6}: pixels=8'h18; {8'h2E,3'd7}: pixels=8'h00;

            // 0x2F '/'
            {8'h2F,3'd0}: pixels=8'h06; {8'h2F,3'd1}: pixels=8'h0C;
            {8'h2F,3'd2}: pixels=8'h18; {8'h2F,3'd3}: pixels=8'h30;
            {8'h2F,3'd4}: pixels=8'h60; {8'h2F,3'd5}: pixels=8'hC0;
            {8'h2F,3'd6}: pixels=8'h80; {8'h2F,3'd7}: pixels=8'h00;

            // 0x30 '0'
            {8'h30,3'd0}: pixels=8'h7C; {8'h30,3'd1}: pixels=8'hC6;
            {8'h30,3'd2}: pixels=8'hCE; {8'h30,3'd3}: pixels=8'hD6;
            {8'h30,3'd4}: pixels=8'hE6; {8'h30,3'd5}: pixels=8'hC6;
            {8'h30,3'd6}: pixels=8'h7C; {8'h30,3'd7}: pixels=8'h00;

            // 0x31 '1'
            {8'h31,3'd0}: pixels=8'h18; {8'h31,3'd1}: pixels=8'h38;
            {8'h31,3'd2}: pixels=8'h18; {8'h31,3'd3}: pixels=8'h18;
            {8'h31,3'd4}: pixels=8'h18; {8'h31,3'd5}: pixels=8'h18;
            {8'h31,3'd6}: pixels=8'h7E; {8'h31,3'd7}: pixels=8'h00;

            // 0x32 '2'
            {8'h32,3'd0}: pixels=8'h7C; {8'h32,3'd1}: pixels=8'hC6;
            {8'h32,3'd2}: pixels=8'h06; {8'h32,3'd3}: pixels=8'h1C;
            {8'h32,3'd4}: pixels=8'h30; {8'h32,3'd5}: pixels=8'h66;
            {8'h32,3'd6}: pixels=8'hFE; {8'h32,3'd7}: pixels=8'h00;

            // 0x33 '3'
            {8'h33,3'd0}: pixels=8'h7C; {8'h33,3'd1}: pixels=8'hC6;
            {8'h33,3'd2}: pixels=8'h06; {8'h33,3'd3}: pixels=8'h3C;
            {8'h33,3'd4}: pixels=8'h06; {8'h33,3'd5}: pixels=8'hC6;
            {8'h33,3'd6}: pixels=8'h7C; {8'h33,3'd7}: pixels=8'h00;

            // 0x34 '4'
            {8'h34,3'd0}: pixels=8'h1C; {8'h34,3'd1}: pixels=8'h3C;
            {8'h34,3'd2}: pixels=8'h6C; {8'h34,3'd3}: pixels=8'hCC;
            {8'h34,3'd4}: pixels=8'hFE; {8'h34,3'd5}: pixels=8'h0C;
            {8'h34,3'd6}: pixels=8'h1E; {8'h34,3'd7}: pixels=8'h00;

            // 0x35 '5'
            {8'h35,3'd0}: pixels=8'hFE; {8'h35,3'd1}: pixels=8'hC0;
            {8'h35,3'd2}: pixels=8'hC0; {8'h35,3'd3}: pixels=8'hFC;
            {8'h35,3'd4}: pixels=8'h06; {8'h35,3'd5}: pixels=8'hC6;
            {8'h35,3'd6}: pixels=8'h7C; {8'h35,3'd7}: pixels=8'h00;

            // 0x36 '6'
            {8'h36,3'd0}: pixels=8'h38; {8'h36,3'd1}: pixels=8'h60;
            {8'h36,3'd2}: pixels=8'hC0; {8'h36,3'd3}: pixels=8'hFC;
            {8'h36,3'd4}: pixels=8'hC6; {8'h36,3'd5}: pixels=8'hC6;
            {8'h36,3'd6}: pixels=8'h7C; {8'h36,3'd7}: pixels=8'h00;

            // 0x37 '7'
            {8'h37,3'd0}: pixels=8'hFE; {8'h37,3'd1}: pixels=8'hC6;
            {8'h37,3'd2}: pixels=8'h0C; {8'h37,3'd3}: pixels=8'h18;
            {8'h37,3'd4}: pixels=8'h30; {8'h37,3'd5}: pixels=8'h30;
            {8'h37,3'd6}: pixels=8'h30; {8'h37,3'd7}: pixels=8'h00;

            // 0x38 '8'
            {8'h38,3'd0}: pixels=8'h7C; {8'h38,3'd1}: pixels=8'hC6;
            {8'h38,3'd2}: pixels=8'hC6; {8'h38,3'd3}: pixels=8'h7C;
            {8'h38,3'd4}: pixels=8'hC6; {8'h38,3'd5}: pixels=8'hC6;
            {8'h38,3'd6}: pixels=8'h7C; {8'h38,3'd7}: pixels=8'h00;

            // 0x39 '9'
            {8'h39,3'd0}: pixels=8'h7C; {8'h39,3'd1}: pixels=8'hC6;
            {8'h39,3'd2}: pixels=8'hC6; {8'h39,3'd3}: pixels=8'h7E;
            {8'h39,3'd4}: pixels=8'h06; {8'h39,3'd5}: pixels=8'h0C;
            {8'h39,3'd6}: pixels=8'h78; {8'h39,3'd7}: pixels=8'h00;

            // 0x3A ':'
            {8'h3A,3'd0}: pixels=8'h00; {8'h3A,3'd1}: pixels=8'h18;
            {8'h3A,3'd2}: pixels=8'h18; {8'h3A,3'd3}: pixels=8'h00;
            {8'h3A,3'd4}: pixels=8'h18; {8'h3A,3'd5}: pixels=8'h18;
            {8'h3A,3'd6}: pixels=8'h00; {8'h3A,3'd7}: pixels=8'h00;

            // 0x3B ';'
            {8'h3B,3'd0}: pixels=8'h00; {8'h3B,3'd1}: pixels=8'h18;
            {8'h3B,3'd2}: pixels=8'h18; {8'h3B,3'd3}: pixels=8'h00;
            {8'h3B,3'd4}: pixels=8'h18; {8'h3B,3'd5}: pixels=8'h18;
            {8'h3B,3'd6}: pixels=8'h30; {8'h3B,3'd7}: pixels=8'h00;

            // 0x3C '<'
            {8'h3C,3'd0}: pixels=8'h06; {8'h3C,3'd1}: pixels=8'h0C;
            {8'h3C,3'd2}: pixels=8'h18; {8'h3C,3'd3}: pixels=8'h30;
            {8'h3C,3'd4}: pixels=8'h18; {8'h3C,3'd5}: pixels=8'h0C;
            {8'h3C,3'd6}: pixels=8'h06; {8'h3C,3'd7}: pixels=8'h00;

            // 0x3D '='
            {8'h3D,3'd0}: pixels=8'h00; {8'h3D,3'd1}: pixels=8'h00;
            {8'h3D,3'd2}: pixels=8'h7E; {8'h3D,3'd3}: pixels=8'h00;
            {8'h3D,3'd4}: pixels=8'h7E; {8'h3D,3'd5}: pixels=8'h00;
            {8'h3D,3'd6}: pixels=8'h00; {8'h3D,3'd7}: pixels=8'h00;

            // 0x3E '>'
            {8'h3E,3'd0}: pixels=8'h60; {8'h3E,3'd1}: pixels=8'h30;
            {8'h3E,3'd2}: pixels=8'h18; {8'h3E,3'd3}: pixels=8'h0C;
            {8'h3E,3'd4}: pixels=8'h18; {8'h3E,3'd5}: pixels=8'h30;
            {8'h3E,3'd6}: pixels=8'h60; {8'h3E,3'd7}: pixels=8'h00;

            // 0x3F '?'
            {8'h3F,3'd0}: pixels=8'h7C; {8'h3F,3'd1}: pixels=8'hC6;
            {8'h3F,3'd2}: pixels=8'h0C; {8'h3F,3'd3}: pixels=8'h18;
            {8'h3F,3'd4}: pixels=8'h18; {8'h3F,3'd5}: pixels=8'h00;
            {8'h3F,3'd6}: pixels=8'h18; {8'h3F,3'd7}: pixels=8'h00;

            // 0x40 '@'
            {8'h40,3'd0}: pixels=8'h7C; {8'h40,3'd1}: pixels=8'hC6;
            {8'h40,3'd2}: pixels=8'hDE; {8'h40,3'd3}: pixels=8'hDE;
            {8'h40,3'd4}: pixels=8'hDE; {8'h40,3'd5}: pixels=8'hC0;
            {8'h40,3'd6}: pixels=8'h7C; {8'h40,3'd7}: pixels=8'h00;

            // 0x41 'A'
            {8'h41,3'd0}: pixels=8'h38; {8'h41,3'd1}: pixels=8'h6C;
            {8'h41,3'd2}: pixels=8'hC6; {8'h41,3'd3}: pixels=8'hFE;
            {8'h41,3'd4}: pixels=8'hC6; {8'h41,3'd5}: pixels=8'hC6;
            {8'h41,3'd6}: pixels=8'hC6; {8'h41,3'd7}: pixels=8'h00;

            // 0x42 'B'
            {8'h42,3'd0}: pixels=8'hFC; {8'h42,3'd1}: pixels=8'hC6;
            {8'h42,3'd2}: pixels=8'hC6; {8'h42,3'd3}: pixels=8'hFC;
            {8'h42,3'd4}: pixels=8'hC6; {8'h42,3'd5}: pixels=8'hC6;
            {8'h42,3'd6}: pixels=8'hFC; {8'h42,3'd7}: pixels=8'h00;

            // 0x43 'C'
            {8'h43,3'd0}: pixels=8'h3C; {8'h43,3'd1}: pixels=8'h66;
            {8'h43,3'd2}: pixels=8'hC0; {8'h43,3'd3}: pixels=8'hC0;
            {8'h43,3'd4}: pixels=8'hC0; {8'h43,3'd5}: pixels=8'h66;
            {8'h43,3'd6}: pixels=8'h3C; {8'h43,3'd7}: pixels=8'h00;

            // 0x44 'D'
            {8'h44,3'd0}: pixels=8'hF8; {8'h44,3'd1}: pixels=8'hCC;
            {8'h44,3'd2}: pixels=8'hC6; {8'h44,3'd3}: pixels=8'hC6;
            {8'h44,3'd4}: pixels=8'hC6; {8'h44,3'd5}: pixels=8'hCC;
            {8'h44,3'd6}: pixels=8'hF8; {8'h44,3'd7}: pixels=8'h00;

            // 0x45 'E'
            {8'h45,3'd0}: pixels=8'hFE; {8'h45,3'd1}: pixels=8'hC0;
            {8'h45,3'd2}: pixels=8'hC0; {8'h45,3'd3}: pixels=8'hF8;
            {8'h45,3'd4}: pixels=8'hC0; {8'h45,3'd5}: pixels=8'hC0;
            {8'h45,3'd6}: pixels=8'hFE; {8'h45,3'd7}: pixels=8'h00;

            // 0x46 'F'
            {8'h46,3'd0}: pixels=8'hFE; {8'h46,3'd1}: pixels=8'hC0;
            {8'h46,3'd2}: pixels=8'hC0; {8'h46,3'd3}: pixels=8'hF8;
            {8'h46,3'd4}: pixels=8'hC0; {8'h46,3'd5}: pixels=8'hC0;
            {8'h46,3'd6}: pixels=8'hC0; {8'h46,3'd7}: pixels=8'h00;

            // 0x47 'G'
            {8'h47,3'd0}: pixels=8'h3C; {8'h47,3'd1}: pixels=8'h66;
            {8'h47,3'd2}: pixels=8'hC0; {8'h47,3'd3}: pixels=8'hC0;
            {8'h47,3'd4}: pixels=8'hCE; {8'h47,3'd5}: pixels=8'h66;
            {8'h47,3'd6}: pixels=8'h3E; {8'h47,3'd7}: pixels=8'h00;

            // 0x48 'H'
            {8'h48,3'd0}: pixels=8'hC6; {8'h48,3'd1}: pixels=8'hC6;
            {8'h48,3'd2}: pixels=8'hC6; {8'h48,3'd3}: pixels=8'hFE;
            {8'h48,3'd4}: pixels=8'hC6; {8'h48,3'd5}: pixels=8'hC6;
            {8'h48,3'd6}: pixels=8'hC6; {8'h48,3'd7}: pixels=8'h00;

            // 0x49 'I'
            {8'h49,3'd0}: pixels=8'h7E; {8'h49,3'd1}: pixels=8'h18;
            {8'h49,3'd2}: pixels=8'h18; {8'h49,3'd3}: pixels=8'h18;
            {8'h49,3'd4}: pixels=8'h18; {8'h49,3'd5}: pixels=8'h18;
            {8'h49,3'd6}: pixels=8'h7E; {8'h49,3'd7}: pixels=8'h00;

            // 0x4A 'J'
            {8'h4A,3'd0}: pixels=8'h1E; {8'h4A,3'd1}: pixels=8'h06;
            {8'h4A,3'd2}: pixels=8'h06; {8'h4A,3'd3}: pixels=8'h06;
            {8'h4A,3'd4}: pixels=8'hC6; {8'h4A,3'd5}: pixels=8'hC6;
            {8'h4A,3'd6}: pixels=8'h7C; {8'h4A,3'd7}: pixels=8'h00;

            // 0x4B 'K'
            {8'h4B,3'd0}: pixels=8'hE6; {8'h4B,3'd1}: pixels=8'hCC;
            {8'h4B,3'd2}: pixels=8'hD8; {8'h4B,3'd3}: pixels=8'hF0;
            {8'h4B,3'd4}: pixels=8'hD8; {8'h4B,3'd5}: pixels=8'hCC;
            {8'h4B,3'd6}: pixels=8'hE6; {8'h4B,3'd7}: pixels=8'h00;

            // 0x4C 'L'
            {8'h4C,3'd0}: pixels=8'hC0; {8'h4C,3'd1}: pixels=8'hC0;
            {8'h4C,3'd2}: pixels=8'hC0; {8'h4C,3'd3}: pixels=8'hC0;
            {8'h4C,3'd4}: pixels=8'hC0; {8'h4C,3'd5}: pixels=8'hC0;
            {8'h4C,3'd6}: pixels=8'hFE; {8'h4C,3'd7}: pixels=8'h00;

            // 0x4D 'M'
            {8'h4D,3'd0}: pixels=8'hC6; {8'h4D,3'd1}: pixels=8'hEE;
            {8'h4D,3'd2}: pixels=8'hFE; {8'h4D,3'd3}: pixels=8'hD6;
            {8'h4D,3'd4}: pixels=8'hC6; {8'h4D,3'd5}: pixels=8'hC6;
            {8'h4D,3'd6}: pixels=8'hC6; {8'h4D,3'd7}: pixels=8'h00;

            // 0x4E 'N'
            {8'h4E,3'd0}: pixels=8'hC6; {8'h4E,3'd1}: pixels=8'hE6;
            {8'h4E,3'd2}: pixels=8'hF6; {8'h4E,3'd3}: pixels=8'hDE;
            {8'h4E,3'd4}: pixels=8'hCE; {8'h4E,3'd5}: pixels=8'hC6;
            {8'h4E,3'd6}: pixels=8'hC6; {8'h4E,3'd7}: pixels=8'h00;

            // 0x4F 'O'
            {8'h4F,3'd0}: pixels=8'h7C; {8'h4F,3'd1}: pixels=8'hC6;
            {8'h4F,3'd2}: pixels=8'hC6; {8'h4F,3'd3}: pixels=8'hC6;
            {8'h4F,3'd4}: pixels=8'hC6; {8'h4F,3'd5}: pixels=8'hC6;
            {8'h4F,3'd6}: pixels=8'h7C; {8'h4F,3'd7}: pixels=8'h00;

            // 0x50 'P'
            {8'h50,3'd0}: pixels=8'hFC; {8'h50,3'd1}: pixels=8'hC6;
            {8'h50,3'd2}: pixels=8'hC6; {8'h50,3'd3}: pixels=8'hFC;
            {8'h50,3'd4}: pixels=8'hC0; {8'h50,3'd5}: pixels=8'hC0;
            {8'h50,3'd6}: pixels=8'hC0; {8'h50,3'd7}: pixels=8'h00;

            // 0x51 'Q'
            {8'h51,3'd0}: pixels=8'h7C; {8'h51,3'd1}: pixels=8'hC6;
            {8'h51,3'd2}: pixels=8'hC6; {8'h51,3'd3}: pixels=8'hC6;
            {8'h51,3'd4}: pixels=8'hD6; {8'h51,3'd5}: pixels=8'hDE;
            {8'h51,3'd6}: pixels=8'h7C; {8'h51,3'd7}: pixels=8'h00;

            // 0x52 'R'
            {8'h52,3'd0}: pixels=8'hFC; {8'h52,3'd1}: pixels=8'hC6;
            {8'h52,3'd2}: pixels=8'hC6; {8'h52,3'd3}: pixels=8'hFC;
            {8'h52,3'd4}: pixels=8'hD8; {8'h52,3'd5}: pixels=8'hCC;
            {8'h52,3'd6}: pixels=8'hC6; {8'h52,3'd7}: pixels=8'h00;

            // 0x53 'S'
            {8'h53,3'd0}: pixels=8'h7C; {8'h53,3'd1}: pixels=8'hC6;
            {8'h53,3'd2}: pixels=8'hC0; {8'h53,3'd3}: pixels=8'h7C;
            {8'h53,3'd4}: pixels=8'h06; {8'h53,3'd5}: pixels=8'hC6;
            {8'h53,3'd6}: pixels=8'h7C; {8'h53,3'd7}: pixels=8'h00;

            // 0x54 'T'
            {8'h54,3'd0}: pixels=8'h7E; {8'h54,3'd1}: pixels=8'h18;
            {8'h54,3'd2}: pixels=8'h18; {8'h54,3'd3}: pixels=8'h18;
            {8'h54,3'd4}: pixels=8'h18; {8'h54,3'd5}: pixels=8'h18;
            {8'h54,3'd6}: pixels=8'h18; {8'h54,3'd7}: pixels=8'h00;

            // 0x55 'U'
            {8'h55,3'd0}: pixels=8'hC6; {8'h55,3'd1}: pixels=8'hC6;
            {8'h55,3'd2}: pixels=8'hC6; {8'h55,3'd3}: pixels=8'hC6;
            {8'h55,3'd4}: pixels=8'hC6; {8'h55,3'd5}: pixels=8'hC6;
            {8'h55,3'd6}: pixels=8'h7C; {8'h55,3'd7}: pixels=8'h00;

            // 0x56 'V'
            {8'h56,3'd0}: pixels=8'hC6; {8'h56,3'd1}: pixels=8'hC6;
            {8'h56,3'd2}: pixels=8'hC6; {8'h56,3'd3}: pixels=8'hC6;
            {8'h56,3'd4}: pixels=8'h6C; {8'h56,3'd5}: pixels=8'h38;
            {8'h56,3'd6}: pixels=8'h10; {8'h56,3'd7}: pixels=8'h00;

            // 0x57 'W'
            {8'h57,3'd0}: pixels=8'hC6; {8'h57,3'd1}: pixels=8'hC6;
            {8'h57,3'd2}: pixels=8'hC6; {8'h57,3'd3}: pixels=8'hD6;
            {8'h57,3'd4}: pixels=8'hFE; {8'h57,3'd5}: pixels=8'hEE;
            {8'h57,3'd6}: pixels=8'hC6; {8'h57,3'd7}: pixels=8'h00;

            // 0x58 'X'
            {8'h58,3'd0}: pixels=8'hC6; {8'h58,3'd1}: pixels=8'hC6;
            {8'h58,3'd2}: pixels=8'h6C; {8'h58,3'd3}: pixels=8'h38;
            {8'h58,3'd4}: pixels=8'h6C; {8'h58,3'd5}: pixels=8'hC6;
            {8'h58,3'd6}: pixels=8'hC6; {8'h58,3'd7}: pixels=8'h00;

            // 0x59 'Y'
            {8'h59,3'd0}: pixels=8'hC6; {8'h59,3'd1}: pixels=8'hC6;
            {8'h59,3'd2}: pixels=8'hC6; {8'h59,3'd3}: pixels=8'h7C;
            {8'h59,3'd4}: pixels=8'h18; {8'h59,3'd5}: pixels=8'h18;
            {8'h59,3'd6}: pixels=8'h18; {8'h59,3'd7}: pixels=8'h00;

            // 0x5A 'Z'
            {8'h5A,3'd0}: pixels=8'hFE; {8'h5A,3'd1}: pixels=8'h06;
            {8'h5A,3'd2}: pixels=8'h0C; {8'h5A,3'd3}: pixels=8'h18;
            {8'h5A,3'd4}: pixels=8'h30; {8'h5A,3'd5}: pixels=8'h60;
            {8'h5A,3'd6}: pixels=8'hFE; {8'h5A,3'd7}: pixels=8'h00;

            // 0x5B '['
            {8'h5B,3'd0}: pixels=8'h3C; {8'h5B,3'd1}: pixels=8'h30;
            {8'h5B,3'd2}: pixels=8'h30; {8'h5B,3'd3}: pixels=8'h30;
            {8'h5B,3'd4}: pixels=8'h30; {8'h5B,3'd5}: pixels=8'h30;
            {8'h5B,3'd6}: pixels=8'h3C; {8'h5B,3'd7}: pixels=8'h00;

            // 0x5C '\'
            {8'h5C,3'd0}: pixels=8'hC0; {8'h5C,3'd1}: pixels=8'h60;
            {8'h5C,3'd2}: pixels=8'h30; {8'h5C,3'd3}: pixels=8'h18;
            {8'h5C,3'd4}: pixels=8'h0C; {8'h5C,3'd5}: pixels=8'h06;
            {8'h5C,3'd6}: pixels=8'h02; {8'h5C,3'd7}: pixels=8'h00;

            // 0x5D ']'
            {8'h5D,3'd0}: pixels=8'h3C; {8'h5D,3'd1}: pixels=8'h0C;
            {8'h5D,3'd2}: pixels=8'h0C; {8'h5D,3'd3}: pixels=8'h0C;
            {8'h5D,3'd4}: pixels=8'h0C; {8'h5D,3'd5}: pixels=8'h0C;
            {8'h5D,3'd6}: pixels=8'h3C; {8'h5D,3'd7}: pixels=8'h00;

            // 0x5E '^'
            {8'h5E,3'd0}: pixels=8'h10; {8'h5E,3'd1}: pixels=8'h38;
            {8'h5E,3'd2}: pixels=8'h6C; {8'h5E,3'd3}: pixels=8'hC6;
            {8'h5E,3'd4}: pixels=8'h00; {8'h5E,3'd5}: pixels=8'h00;
            {8'h5E,3'd6}: pixels=8'h00; {8'h5E,3'd7}: pixels=8'h00;

            // 0x5F '_'
            {8'h5F,3'd0}: pixels=8'h00; {8'h5F,3'd1}: pixels=8'h00;
            {8'h5F,3'd2}: pixels=8'h00; {8'h5F,3'd3}: pixels=8'h00;
            {8'h5F,3'd4}: pixels=8'h00; {8'h5F,3'd5}: pixels=8'h00;
            {8'h5F,3'd6}: pixels=8'h00; {8'h5F,3'd7}: pixels=8'hFF;

            // 0x60 '`'
            {8'h60,3'd0}: pixels=8'h30; {8'h60,3'd1}: pixels=8'h18;
            {8'h60,3'd2}: pixels=8'h0C; {8'h60,3'd3}: pixels=8'h00;
            {8'h60,3'd4}: pixels=8'h00; {8'h60,3'd5}: pixels=8'h00;
            {8'h60,3'd6}: pixels=8'h00; {8'h60,3'd7}: pixels=8'h00;

            // 0x61 'a'
            {8'h61,3'd0}: pixels=8'h00; {8'h61,3'd1}: pixels=8'h00;
            {8'h61,3'd2}: pixels=8'h7C; {8'h61,3'd3}: pixels=8'h06;
            {8'h61,3'd4}: pixels=8'h7E; {8'h61,3'd5}: pixels=8'hC6;
            {8'h61,3'd6}: pixels=8'h7E; {8'h61,3'd7}: pixels=8'h00;

            // 0x62 'b'
            {8'h62,3'd0}: pixels=8'hC0; {8'h62,3'd1}: pixels=8'hC0;
            {8'h62,3'd2}: pixels=8'hFC; {8'h62,3'd3}: pixels=8'hC6;
            {8'h62,3'd4}: pixels=8'hC6; {8'h62,3'd5}: pixels=8'hC6;
            {8'h62,3'd6}: pixels=8'hFC; {8'h62,3'd7}: pixels=8'h00;

            // 0x63 'c'
            {8'h63,3'd0}: pixels=8'h00; {8'h63,3'd1}: pixels=8'h00;
            {8'h63,3'd2}: pixels=8'h7C; {8'h63,3'd3}: pixels=8'hC6;
            {8'h63,3'd4}: pixels=8'hC0; {8'h63,3'd5}: pixels=8'hC6;
            {8'h63,3'd6}: pixels=8'h7C; {8'h63,3'd7}: pixels=8'h00;

            // 0x64 'd'
            {8'h64,3'd0}: pixels=8'h06; {8'h64,3'd1}: pixels=8'h06;
            {8'h64,3'd2}: pixels=8'h7E; {8'h64,3'd3}: pixels=8'hC6;
            {8'h64,3'd4}: pixels=8'hC6; {8'h64,3'd5}: pixels=8'hC6;
            {8'h64,3'd6}: pixels=8'h7E; {8'h64,3'd7}: pixels=8'h00;

            // 0x65 'e'
            {8'h65,3'd0}: pixels=8'h00; {8'h65,3'd1}: pixels=8'h00;
            {8'h65,3'd2}: pixels=8'h7C; {8'h65,3'd3}: pixels=8'hC6;
            {8'h65,3'd4}: pixels=8'hFE; {8'h65,3'd5}: pixels=8'hC0;
            {8'h65,3'd6}: pixels=8'h7C; {8'h65,3'd7}: pixels=8'h00;

            // 0x66 'f'
            {8'h66,3'd0}: pixels=8'h1C; {8'h66,3'd1}: pixels=8'h36;
            {8'h66,3'd2}: pixels=8'h30; {8'h66,3'd3}: pixels=8'h78;
            {8'h66,3'd4}: pixels=8'h30; {8'h66,3'd5}: pixels=8'h30;
            {8'h66,3'd6}: pixels=8'h30; {8'h66,3'd7}: pixels=8'h00;

            // 0x67 'g'
            {8'h67,3'd0}: pixels=8'h00; {8'h67,3'd1}: pixels=8'h00;
            {8'h67,3'd2}: pixels=8'h7E; {8'h67,3'd3}: pixels=8'hC6;
            {8'h67,3'd4}: pixels=8'hC6; {8'h67,3'd5}: pixels=8'h7E;
            {8'h67,3'd6}: pixels=8'h06; {8'h67,3'd7}: pixels=8'h7C;

            // 0x68 'h'
            {8'h68,3'd0}: pixels=8'hC0; {8'h68,3'd1}: pixels=8'hC0;
            {8'h68,3'd2}: pixels=8'hFC; {8'h68,3'd3}: pixels=8'hC6;
            {8'h68,3'd4}: pixels=8'hC6; {8'h68,3'd5}: pixels=8'hC6;
            {8'h68,3'd6}: pixels=8'hC6; {8'h68,3'd7}: pixels=8'h00;

            // 0x69 'i'
            {8'h69,3'd0}: pixels=8'h18; {8'h69,3'd1}: pixels=8'h00;
            {8'h69,3'd2}: pixels=8'h38; {8'h69,3'd3}: pixels=8'h18;
            {8'h69,3'd4}: pixels=8'h18; {8'h69,3'd5}: pixels=8'h18;
            {8'h69,3'd6}: pixels=8'h3C; {8'h69,3'd7}: pixels=8'h00;

            // 0x6A 'j'
            {8'h6A,3'd0}: pixels=8'h06; {8'h6A,3'd1}: pixels=8'h00;
            {8'h6A,3'd2}: pixels=8'h06; {8'h6A,3'd3}: pixels=8'h06;
            {8'h6A,3'd4}: pixels=8'h06; {8'h6A,3'd5}: pixels=8'hC6;
            {8'h6A,3'd6}: pixels=8'h7C; {8'h6A,3'd7}: pixels=8'h00;

            // 0x6B 'k'
            {8'h6B,3'd0}: pixels=8'hC0; {8'h6B,3'd1}: pixels=8'hC0;
            {8'h6B,3'd2}: pixels=8'hCC; {8'h6B,3'd3}: pixels=8'hD8;
            {8'h6B,3'd4}: pixels=8'hF0; {8'h6B,3'd5}: pixels=8'hD8;
            {8'h6B,3'd6}: pixels=8'hCC; {8'h6B,3'd7}: pixels=8'h00;

            // 0x6C 'l'
            {8'h6C,3'd0}: pixels=8'h38; {8'h6C,3'd1}: pixels=8'h18;
            {8'h6C,3'd2}: pixels=8'h18; {8'h6C,3'd3}: pixels=8'h18;
            {8'h6C,3'd4}: pixels=8'h18; {8'h6C,3'd5}: pixels=8'h18;
            {8'h6C,3'd6}: pixels=8'h3C; {8'h6C,3'd7}: pixels=8'h00;

            // 0x6D 'm'
            {8'h6D,3'd0}: pixels=8'h00; {8'h6D,3'd1}: pixels=8'h00;
            {8'h6D,3'd2}: pixels=8'hEC; {8'h6D,3'd3}: pixels=8'hFE;
            {8'h6D,3'd4}: pixels=8'hD6; {8'h6D,3'd5}: pixels=8'hC6;
            {8'h6D,3'd6}: pixels=8'hC6; {8'h6D,3'd7}: pixels=8'h00;

            // 0x6E 'n'
            {8'h6E,3'd0}: pixels=8'h00; {8'h6E,3'd1}: pixels=8'h00;
            {8'h6E,3'd2}: pixels=8'hDC; {8'h6E,3'd3}: pixels=8'hE6;
            {8'h6E,3'd4}: pixels=8'hC6; {8'h6E,3'd5}: pixels=8'hC6;
            {8'h6E,3'd6}: pixels=8'hC6; {8'h6E,3'd7}: pixels=8'h00;

            // 0x6F 'o'
            {8'h6F,3'd0}: pixels=8'h00; {8'h6F,3'd1}: pixels=8'h00;
            {8'h6F,3'd2}: pixels=8'h7C; {8'h6F,3'd3}: pixels=8'hC6;
            {8'h6F,3'd4}: pixels=8'hC6; {8'h6F,3'd5}: pixels=8'hC6;
            {8'h6F,3'd6}: pixels=8'h7C; {8'h6F,3'd7}: pixels=8'h00;

            // 0x70 'p'
            {8'h70,3'd0}: pixels=8'h00; {8'h70,3'd1}: pixels=8'h00;
            {8'h70,3'd2}: pixels=8'hFC; {8'h70,3'd3}: pixels=8'hC6;
            {8'h70,3'd4}: pixels=8'hC6; {8'h70,3'd5}: pixels=8'hFC;
            {8'h70,3'd6}: pixels=8'hC0; {8'h70,3'd7}: pixels=8'hC0;

            // 0x71 'q'
            {8'h71,3'd0}: pixels=8'h00; {8'h71,3'd1}: pixels=8'h00;
            {8'h71,3'd2}: pixels=8'h7E; {8'h71,3'd3}: pixels=8'hC6;
            {8'h71,3'd4}: pixels=8'hC6; {8'h71,3'd5}: pixels=8'h7E;
            {8'h71,3'd6}: pixels=8'h06; {8'h71,3'd7}: pixels=8'h06;

            // 0x72 'r'
            {8'h72,3'd0}: pixels=8'h00; {8'h72,3'd1}: pixels=8'h00;
            {8'h72,3'd2}: pixels=8'hDC; {8'h72,3'd3}: pixels=8'hE6;
            {8'h72,3'd4}: pixels=8'hC0; {8'h72,3'd5}: pixels=8'hC0;
            {8'h72,3'd6}: pixels=8'hC0; {8'h72,3'd7}: pixels=8'h00;

            // 0x73 's'
            {8'h73,3'd0}: pixels=8'h00; {8'h73,3'd1}: pixels=8'h00;
            {8'h73,3'd2}: pixels=8'h7C; {8'h73,3'd3}: pixels=8'hC0;
            {8'h73,3'd4}: pixels=8'h7C; {8'h73,3'd5}: pixels=8'h06;
            {8'h73,3'd6}: pixels=8'hFC; {8'h73,3'd7}: pixels=8'h00;

            // 0x74 't'
            {8'h74,3'd0}: pixels=8'h30; {8'h74,3'd1}: pixels=8'h30;
            {8'h74,3'd2}: pixels=8'hFC; {8'h74,3'd3}: pixels=8'h30;
            {8'h74,3'd4}: pixels=8'h30; {8'h74,3'd5}: pixels=8'h36;
            {8'h74,3'd6}: pixels=8'h1C; {8'h74,3'd7}: pixels=8'h00;

            // 0x75 'u'
            {8'h75,3'd0}: pixels=8'h00; {8'h75,3'd1}: pixels=8'h00;
            {8'h75,3'd2}: pixels=8'hC6; {8'h75,3'd3}: pixels=8'hC6;
            {8'h75,3'd4}: pixels=8'hC6; {8'h75,3'd5}: pixels=8'hC6;
            {8'h75,3'd6}: pixels=8'h7E; {8'h75,3'd7}: pixels=8'h00;

            // 0x76 'v'
            {8'h76,3'd0}: pixels=8'h00; {8'h76,3'd1}: pixels=8'h00;
            {8'h76,3'd2}: pixels=8'hC6; {8'h76,3'd3}: pixels=8'hC6;
            {8'h76,3'd4}: pixels=8'hC6; {8'h76,3'd5}: pixels=8'h6C;
            {8'h76,3'd6}: pixels=8'h38; {8'h76,3'd7}: pixels=8'h00;

            // 0x77 'w'
            {8'h77,3'd0}: pixels=8'h00; {8'h77,3'd1}: pixels=8'h00;
            {8'h77,3'd2}: pixels=8'hC6; {8'h77,3'd3}: pixels=8'hC6;
            {8'h77,3'd4}: pixels=8'hD6; {8'h77,3'd5}: pixels=8'hFE;
            {8'h77,3'd6}: pixels=8'h6C; {8'h77,3'd7}: pixels=8'h00;

            // 0x78 'x'
            {8'h78,3'd0}: pixels=8'h00; {8'h78,3'd1}: pixels=8'h00;
            {8'h78,3'd2}: pixels=8'hC6; {8'h78,3'd3}: pixels=8'h6C;
            {8'h78,3'd4}: pixels=8'h38; {8'h78,3'd5}: pixels=8'h6C;
            {8'h78,3'd6}: pixels=8'hC6; {8'h78,3'd7}: pixels=8'h00;

            // 0x79 'y'
            {8'h79,3'd0}: pixels=8'h00; {8'h79,3'd1}: pixels=8'h00;
            {8'h79,3'd2}: pixels=8'hC6; {8'h79,3'd3}: pixels=8'hC6;
            {8'h79,3'd4}: pixels=8'hC6; {8'h79,3'd5}: pixels=8'h7E;
            {8'h79,3'd6}: pixels=8'h06; {8'h79,3'd7}: pixels=8'h7C;

            // 0x7A 'z'
            {8'h7A,3'd0}: pixels=8'h00; {8'h7A,3'd1}: pixels=8'h00;
            {8'h7A,3'd2}: pixels=8'hFE; {8'h7A,3'd3}: pixels=8'h0C;
            {8'h7A,3'd4}: pixels=8'h18; {8'h7A,3'd5}: pixels=8'h30;
            {8'h7A,3'd6}: pixels=8'hFE; {8'h7A,3'd7}: pixels=8'h00;

            // 0x7B '{'
            {8'h7B,3'd0}: pixels=8'h0E; {8'h7B,3'd1}: pixels=8'h18;
            {8'h7B,3'd2}: pixels=8'h18; {8'h7B,3'd3}: pixels=8'h70;
            {8'h7B,3'd4}: pixels=8'h18; {8'h7B,3'd5}: pixels=8'h18;
            {8'h7B,3'd6}: pixels=8'h0E; {8'h7B,3'd7}: pixels=8'h00;

            // 0x7C '|'
            {8'h7C,3'd0}: pixels=8'h18; {8'h7C,3'd1}: pixels=8'h18;
            {8'h7C,3'd2}: pixels=8'h18; {8'h7C,3'd3}: pixels=8'h00;
            {8'h7C,3'd4}: pixels=8'h18; {8'h7C,3'd5}: pixels=8'h18;
            {8'h7C,3'd6}: pixels=8'h18; {8'h7C,3'd7}: pixels=8'h00;

            // 0x7D '}'
            {8'h7D,3'd0}: pixels=8'h70; {8'h7D,3'd1}: pixels=8'h18;
            {8'h7D,3'd2}: pixels=8'h18; {8'h7D,3'd3}: pixels=8'h0E;
            {8'h7D,3'd4}: pixels=8'h18; {8'h7D,3'd5}: pixels=8'h18;
            {8'h7D,3'd6}: pixels=8'h70; {8'h7D,3'd7}: pixels=8'h00;

            // 0x7E '~'
            {8'h7E,3'd0}: pixels=8'h76; {8'h7E,3'd1}: pixels=8'hDC;
            {8'h7E,3'd2}: pixels=8'h00; {8'h7E,3'd3}: pixels=8'h00;
            {8'h7E,3'd4}: pixels=8'h00; {8'h7E,3'd5}: pixels=8'h00;
            {8'h7E,3'd6}: pixels=8'h00; {8'h7E,3'd7}: pixels=8'h00;

            // 0x7F (unused/delete)
            {8'h7F,3'd0}: pixels=8'h00; {8'h7F,3'd1}: pixels=8'h00;
            {8'h7F,3'd2}: pixels=8'h00; {8'h7F,3'd3}: pixels=8'h00;
            {8'h7F,3'd4}: pixels=8'h00; {8'h7F,3'd5}: pixels=8'h00;
            {8'h7F,3'd6}: pixels=8'h00; {8'h7F,3'd7}: pixels=8'h00;

            default: pixels = 8'h00;
        endcase
    end
endmodule
