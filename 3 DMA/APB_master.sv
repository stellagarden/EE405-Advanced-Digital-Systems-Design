// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : APB_master.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: APB master
//              This module is emulate APB master in FPGA.
//              Luckily, completed version is provided... :)
// -FHDR------------------------------------------------------------
`timescale 1ns / 1ps

interface APB_master_intf
#(
    parameter PPROT_WIDTH                           = 3,
    parameter PSTRB_WIDTH                           = 4,
    parameter ADDR_WIDTH                            = 32,
    parameter DATA_WIDTH                            = 32
)
(
    input  logic                                    clk,
    input  logic                                    resetn,
    output logic [ADDR_WIDTH-1:0]                   m_apb_paddr,
    output logic                                    m_apb_penable,
    output logic [PPROT_WIDTH-1:0]                  m_apb_pprot,
    input  logic [DATA_WIDTH-1:0]                   m_apb_prdata,
    input  logic                                    m_apb_pready,
    output logic                                    m_apb_psel,
    input  logic                                    m_apb_pslverr,
    output logic [PSTRB_WIDTH-1:0]                  m_apb_pstrb,
    output logic [DATA_WIDTH-1:0]                   m_apb_pwdata,
    output logic                                    m_apb_pwrite
);

    task automatic write (
        input  logic [ADDR_WIDTH-1:0]               apb_paddr,
        input  logic [DATA_WIDTH-1:0]               apb_pwdata
    );

        m_apb_pprot                                 = {PPROT_WIDTH{1'b0}};
        m_apb_pstrb                                 = {DATA_WIDTH/8{1'b1}};

        @(posedge clk);
        // SETUP state
        m_apb_psel                                  = 'b1;
        m_apb_pwrite                                = 'b1;
        m_apb_paddr                                 = apb_paddr;
        m_apb_pwdata                                = apb_pwdata;

        @(posedge clk);
        // ACCESS state
        m_apb_penable                               = 'b1;

        wait(m_apb_pready);

        @(posedge clk);
        m_apb_psel                                  = 'b0;
        m_apb_penable                               = 'b0;
        //$display ("APB: [%0dns] Inst: write    Addr: %h    Data: %h", $time, apb_paddr, apb_pwdata);

    endtask

    task automatic read (
        input  logic [ADDR_WIDTH-1:0]               apb_paddr,
        output logic [DATA_WIDTH-1:0]               apb_prdata
    );

        m_apb_pprot                                 = {PPROT_WIDTH{1'b0}};
        m_apb_pstrb                                 = {DATA_WIDTH/8{1'b1}};

        @(posedge clk);
        // SETUP state
        m_apb_psel                                  = 'b1;
        m_apb_pwrite                                = 'b0;
        m_apb_paddr                                 = apb_paddr;

        @(posedge clk);
        m_apb_penable                               = 'b1;

        wait(m_apb_pready);

        @(posedge clk);
        apb_prdata                                  = m_apb_prdata;
        m_apb_psel                                  = 'b0;
        m_apb_penable                               = 'b0;
        //$display ("APB: [%0dnx] Inst: read    Addr: %h    Data: %h", $time, apb_paddr, apb_prdata);

    endtask

endinterface