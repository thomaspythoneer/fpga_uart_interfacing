/*
# Team ID:         eYRC#3750
# Theme:           MazeSolver Bot
# Author List:     Rohan Maheshwari, Rakshit Joshi
# Filename:        t1b_ultrasonic.v
# File Description: This module is a controller for an HC-SR04 ultrasonic sensor.
#                   It operates using a state machine to generate a 10us trigger
#                   pulse for the sensor. It then waits for and measures the
#                   duration of the returning echo pulse. Based on this duration,
#                   it calculates the distance to an object in millimeters and
#                   provides an output flag to indicate when an object is detected
#                   within 70mm. The design uses an active-low reset.
# Global variables: None
*/

// module Declaration
module t1b_ultrasonic(
    input clk_50M, reset, echo_rx,
    output reg trig,
    output op,
    output wire [15:0] distance_out
);

initial begin
    trig = 0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////



localparam CYCLE_LENGTH        = 600554; 
localparam TRIGGER_PULSE_WIDTH = 500;    
localparam INIT_DELAY_LENGTH   = 51;     


parameter S_INIT_DELAY = 2'd0; 
parameter S_RUN        = 2'd1; 
parameter S_IDLE       = 2'd0; 
parameter S_WAIT_ECHO  = 2'd1; 
parameter S_MEASURE    = 2'd2; 


reg [1:0] state = S_INIT_DELAY;     
reg [1:0] sub_state = S_IDLE;      

reg [19:0] cycle_counter = 0;      
reg [6:0] delay_counter = 0;      
reg [19:0] echo_counter = 0;        

reg [15:0] distance = 0;            
reg detection = 0;                 


wire [31:0] distance_product = echo_counter * 34;
wire [15:0] calculated_distance = distance_product / 10000; 

always @(posedge clk_50M or negedge reset) begin
    if (!reset) begin                           // Asynchronous active-low reset initializes all registers.
        state <= S_INIT_DELAY;
        sub_state <= S_IDLE;
        trig <= 1'b0;
        cycle_counter <= 0;
        delay_counter <= 0;
        echo_counter <= 0;
        distance <= 0;
        detection <= 0;
    end else begin
        
        case (state)                                                // Main FSM: handles the overall startup and run sequence.
            S_INIT_DELAY: begin
                if (delay_counter == INIT_DELAY_LENGTH - 1) begin
                    state <= S_RUN;
                    cycle_counter <= 0;
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end

            S_RUN: begin
                if (cycle_counter == CYCLE_LENGTH - 1) begin
                    cycle_counter <= 0;
                end else begin
                    cycle_counter <= cycle_counter + 1;
                end

                trig <= (cycle_counter < TRIGGER_PULSE_WIDTH);      // Generates the 10us trigger pulse for the sensor.
                
                case (sub_state)                                    // Nested FSM: handles the specific steps of a single measurement.
                    S_IDLE: begin
                        if (cycle_counter == TRIGGER_PULSE_WIDTH) begin
                            sub_state <= S_WAIT_ECHO;               // Timeout if no echo is received by the end of the cycle.
                            
                            if (!echo_rx) begin
                                distance <= 0;
                                detection <= 0;
                            end
                        end
                    end

                    S_WAIT_ECHO: begin                               // Waits for the echo pulse to begin (rising edge).
                        if (echo_rx) begin
                            sub_state <= S_MEASURE;
                            echo_counter <= 0;
                        end else if (cycle_counter == (TRIGGER_PULSE_WIDTH + 1)) begin
                            distance <= 0;
                            detection <= 0;
                        end else if (cycle_counter == CYCLE_LENGTH - 1) begin
                            distance <= 0;
                            detection <= 1'b0;
                            sub_state <= S_IDLE;
                        end
                    end

                    S_MEASURE: begin
                        if (cycle_counter == CYCLE_LENGTH - 1) begin
                            distance <= 0;
                            detection <= 1'b0;
                            echo_counter <= 0;
                            sub_state <= S_IDLE;
                        end else if (echo_rx) begin
                            echo_counter <= echo_counter + 1;           // While the echo is high, increment the counter to measure its duration.
                        end else begin
                            distance <= calculated_distance;            // When the echo ends, calculate distance and set detection flag.
                            detection <= (calculated_distance < 70);
                            sub_state <= S_IDLE;
                        end
                    end
                endcase
            end
        endcase
    end
end


// Assignments to outputs using renamed internal registers
assign op = detection;
assign distance_out = distance;


//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule