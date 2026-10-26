module secure_fsm_top (
    input logic clk,
    input logic rst_n,
    input logic auth_in,
    input logic [3:0] fault_mask,
    output logic access_granted,
    output logic attack_detected,
    output logic dmr_err,
    output logic parity_err,
    output logic tmr_err,
    output logic ecc_err,
    output logic ecc_corr,
    output logic ecc_unc,
    output logic [3:0] state_out,
    output logic [3:0] voted_state,
    output logic [3:0] ecc_state
);

    logic [3:0] raw_state_a, raw_state_b, raw_state_c;
    logic [3:0] injected_state;
    logic p_q_a, p_q_b, p_q_c;
    logic [3:0] ecc_q_a;

    auth_fsm fsm_a (
        .clk(clk),
        .rst_n(rst_n),
        .auth_in(auth_in),
        .access_granted(access_granted),
        .state_out(raw_state_a),
        .parity_q(p_q_a),
        .ecc_q(ecc_q_a)
    );

    assign injected_state = raw_state_a ^ fault_mask;
    assign state_out = injected_state;

    auth_fsm fsm_b (
        .clk(clk),
        .rst_n(rst_n),
        .auth_in(auth_in),
        .access_granted(),
        .state_out(raw_state_b),
        .parity_q(p_q_b),
        .ecc_q()
    );

    auth_fsm fsm_c (
        .clk(clk),
        .rst_n(rst_n),
        .auth_in(auth_in),
        .access_granted(),
        .state_out(raw_state_c),
        .parity_q(p_q_c),
        .ecc_q()
    );

    assign parity_err = (^injected_state) ^ p_q_a;

    assign dmr_err = (injected_state != raw_state_b);

    assign voted_state = (injected_state & raw_state_b) | 
                         (raw_state_b & raw_state_c) | 
                         (injected_state & raw_state_c);
    assign tmr_err = (injected_state != voted_state);

    assign ecc_state = injected_state;
    assign ecc_err   = (injected_state != ecc_q_a);
    assign ecc_corr  = ecc_err;
    assign ecc_unc   = parity_err & ecc_err;

    assign attack_detected = dmr_err | parity_err | tmr_err | ecc_err;

endmodule
