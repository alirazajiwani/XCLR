module vga_timing (
    input  logic clk,
    input  logic reset_n,
    output logic hsync,
    output logic vsync,
    output logic [9:0] pixel_x,
    output logic [8:0] pixel_y,
    output logic active_video
);

    // VGA 160x100 @60Hz timing parameters
    parameter H_A  = 160;   // Horizontal active
    parameter H_FP = 8;     // Horizontal front porch
    parameter H_S  = 8;     // Horizontal sync
    parameter H_BP = 16;    // Horizontal back porch
    
    parameter V_A  = 100;   // Vertical active
    parameter V_FP = 3;     // Vertical front porch
    parameter V_S  = 6;     // Vertical sync
    parameter V_BP = 6;     // Vertical back porch

    // FSM states
    typedef enum logic [1:0] {
        Hbp = 2'b00,    // Horizontal Back Porch
        Ha  = 2'b01,    // Horizontal Active
        Hfp = 2'b10,    // Horizontal Front Porch
        Hs  = 2'b11     // Horizontal Sync
    } h_state_t;

    typedef enum logic [1:0] {
        Vbp = 2'b00,    // Vertical Back Porch
        Va  = 2'b01,    // Vertical Active
        Vfp = 2'b10,    // Vertical Front Porch
        Vs  = 2'b11     // Vertical Sync
    } v_state_t;

    h_state_t h_state;
    v_state_t v_state;

    // Counters
    logic [9:0] h_count;
    logic [9:0] v_count;
    logic [9:0] pixel_x_reg;
    logic [8:0] pixel_y_reg;
    
    logic end_of_line;  // Signal to indicate end of horizontal line

    // Horizontal FSM
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            h_state <= Hbp;
            h_count <= 10'd0;
            pixel_x_reg <= 10'd0;
        end else begin
            case (h_state)
                Hbp: begin
                    if (h_count == H_BP - 1) begin
                        h_count <= 10'd0;
                        pixel_x_reg <= 10'd0;
                        h_state <= Ha;
                    end else begin
                        h_count <= h_count + 10'd1;
                    end
                end

                Ha: begin
                    if (h_count == H_A - 1) begin
                        h_count <= 10'd0;
                        h_state <= Hfp;
                    end else begin
                        h_count <= h_count + 10'd1;
                        pixel_x_reg <= pixel_x_reg + 10'd1;
                    end
                end

                Hfp: begin
                    if (h_count == H_FP - 1) begin
                        h_count <= 10'd0;
                        h_state <= Hs;
                    end else begin
                        h_count <= h_count + 10'd1;
                    end
                end

                Hs: begin
                    if (h_count == H_S - 1) begin
                        h_count <= 10'd0;
                        h_state <= Hbp;
                    end else begin
                        h_count <= h_count + 10'd1;
                    end
                end

                default: h_state <= Hbp;
            endcase
        end
    end

    // End of line detection (when Hs completes)
    assign end_of_line = (h_state == Hs) && (h_count == H_S - 1);

    // Vertical FSM
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            v_state <= Vbp;
            v_count <= 10'd0;
            pixel_y_reg <= 9'd0;
        end else begin
            if (end_of_line) begin  // Only advance vertical state at end of each line
                case (v_state)
                    Vbp: begin
                        if (v_count == V_BP - 1) begin
                            v_count <= 10'd0;
                            pixel_y_reg <= 9'd0;
                            v_state <= Va;
                        end else begin
                            v_count <= v_count + 10'd1;
                        end
                    end

                    Va: begin
                        if (v_count == V_A - 1) begin
                            v_count <= 10'd0;
                            v_state <= Vfp;
                        end else begin
                            v_count <= v_count + 10'd1;
                            pixel_y_reg <= pixel_y_reg + 9'd1;
                        end
                    end

                    Vfp: begin
                        if (v_count == V_FP - 1) begin
                            v_count <= 10'd0;
                            v_state <= Vs;
                        end else begin
                            v_count <= v_count + 10'd1;
                        end
                    end

                    Vs: begin
                        if (v_count == V_S - 1) begin
                            v_count <= 10'd0;
                            v_state <= Vbp;
                        end else begin
                            v_count <= v_count + 10'd1;
                        end
                    end

                    default: v_state <= Vbp;
                endcase
            end
        end
    end

    // Output assignments with registered outputs
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            hsync <= 1'b1;  // Initialize to inactive (high)
            vsync <= 1'b1;  // Initialize to inactive (high)
        end else begin
            hsync <= (h_state == Hs) ? 1'b0 : 1'b1;  // Active low
            vsync <= (v_state == Vs) ? 1'b0 : 1'b1;  // Active low
        end
    end
    
    assign active_video = (h_state == Ha) && (v_state == Va);
    assign pixel_x = (active_video) ? pixel_x_reg : 10'd0;
    assign pixel_y = (active_video) ? pixel_y_reg : 9'd0;

endmodule