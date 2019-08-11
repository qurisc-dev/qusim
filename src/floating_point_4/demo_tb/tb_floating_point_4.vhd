---------------------------------------------------------------------------
--
--  (c) Copyright 2011, 2012, 2015 Xilinx, Inc. All rights reserved.
--
--  This file contains confidential and proprietary information
--  of Xilinx, Inc. and is protected under U.S. and
--  international copyright and other intellectual property
--  laws.
--
--  DISCLAIMER
--  This disclaimer is not a license and does not grant any
--  rights to the materials distributed herewith. Except as
--  otherwise provided in a valid license issued to you by
--  Xilinx, and to the maximum extent permitted by applicable
--  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
--  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
--  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
--  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
--  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
--  (2) Xilinx shall not be liable (whether in contract or tort,
--  including negligence, or under any other theory of
--  liability) for any loss or damage of any kind or nature
--  related to, arising under or in connection with these
--  materials, including for any direct, or any indirect,
--  special, incidental, or consequential loss or damage
--  (including loss of data, profits, goodwill, or any type of
--  loss or damage suffered as a result of any action brought
--  by a third party) even if such damage or loss was
--  reasonably foreseeable or Xilinx had been advised of the
--  possibility of the same.
--
--  CRITICAL APPLICATIONS
--  Xilinx products are not designed or intended to be fail-
--  safe, or for use in any application requiring fail-safe
--  performance, such as life-support or safety devices or
--  systems, Class III medical devices, nuclear facilities,
--  applications related to the deployment of airbags, or any
--  other applications that could lead to death, personal
--  injury, or severe property or environmental damage
--  (individually and collectively, "Critical
--  Applications"). Customer assumes the sole risk and
--  liability of any use of Xilinx products in Critical
--  Applications, subject only to applicable laws and
--  regulations governing limitations on product liability.
--
--  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
--  PART OF THIS FILE AT ALL TIMES.
--
---------------------------------------------------------------------------
-- Description:
-- This is an example testbench for the Floating-point IP core.
-- The testbench has been generated by Vivado to accompany the IP core
-- instance you have generated.
--
-- This testbench is for demonstration purposes only.  See note below for
-- instructions on how to use it with your core.
--
-- See the Floating Point Operator datasheet for further information about
-- this core.
--
---------------------------------------------------------------------------
-- Using this testbench
--
-- This testbench instantiates your generated Floating-point core
-- instance named "floating_point_4".
--
-- Use Vivado's Run Simulation flow to run this testbench.  See the Vivado
-- documentation for details.
---------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_floating_point_4 is
end tb_floating_point_4;

architecture tb of tb_floating_point_4 is

  -----------------------------------------------------------------------
  -- Timing constants
  -----------------------------------------------------------------------
  constant CLOCK_PERIOD : time := 100 ns;
  constant T_HOLD       : time := 10 ns;
  constant T_STROBE     : time := CLOCK_PERIOD - (1 ns);
  constant DUT_DELAY    : time := CLOCK_PERIOD * 22;

  -----------------------------------------------------------------------
  -- Testbench types and signals
  -----------------------------------------------------------------------

  -- Overall simulation phase control enumerated type and signal
  type sim_phase_t is (phase_init,           -- test initialization, run no operations
                       phase_single,         -- run a single operation, and wait for the result
                       phase_consecutive,    -- run a consecutive series of 100 operations with incrementing data
                       phase_axi_handshake,  -- demonstrate the use and effect of AXI handshaking signals
                       phase_aresetn,        -- demonstrate the use of synchronous reset
                       phase_special         -- demonstrate the use of special floating-point values
                       );
  signal sim_phase : sim_phase_t := phase_init;

  -- Enumerated type to indicate special floating point values.
  -- Note: denormalized numbers are treated as zero, and signalling NaNs are treated as quiet NaNs.
  -- Out Of Range just means the value is larger than VHDL can support in a Real type
  type floating_point_special_t is (normal, zero_pos, zero_neg, inf_pos, inf_neg, nan, out_of_range);

  -----------------------------------------------------------------------
  -- Functions
  -----------------------------------------------------------------------

  -- Function to limit an integer bit width to a value for which functions can use VHDL's integer type for calculations
  function width_limit(w : integer) return integer is
    constant MAX_WIDTH : integer := 30;  -- maximum width: allows 2**width to be stored in an integer variable
  begin
    if w < MAX_WIDTH then
      return w;
    else
      return MAX_WIDTH;
    end if;
  end function width_limit;


  -- Function to identify special numbers in a std_logic_vector floating point representation
  function flt_to_special(f : std_logic_vector;  -- floating point number to convert
                          w, fw : integer)       -- total and fractional bit width of result
    return floating_point_special_t is
    constant EW     : integer := w - fw;
    constant ZEROS  : std_logic_vector(w-1 downto 0)    := (others => '0');
    constant ONES   : std_logic_vector(w-1 downto 0)    := (others => '1');
    variable f_int  : std_logic_vector(f'high downto 0) := f;  -- fixed width version of f
    variable f_sign : std_logic                         := f_int(w-1);              -- sign bit of f
    variable f_exp  : std_logic_vector(EW-1 downto 0)   := f_int(w-2 downto fw-1);  -- exponent of f
    variable f_mant : std_logic_vector(fw-2 downto 0)   := f_int(fw-2 downto 0);    -- mantissa of f
    variable result : floating_point_special_t;
    constant E_BIAS   : integer := 2 ** (EW - 1) - 1;
  begin

    -- Check bit widths match
    assert f'high = w - 1
      report "ERROR: flt_to_special: input std_logic_vector f must have bit width = input integer w"
      severity failure;

    -- Check for special cases
    if f_exp = ZEROS(w-2 downto fw-1) then
      -- +/- zero (treat denormalized numbers as zero)
      if f_sign = '0' then
        result := zero_pos;
      else
        result := zero_neg;
      end if;

    elsif f_exp = ONES(w-2 downto fw-1) then
      if f_mant = ZEROS(fw-2 downto 0) then
        -- +/- infinity
        if f_sign = '0' then
          result := inf_pos;
        else
          result := inf_neg;
        end if;

      else
        -- NaN (not a number)
        result := nan;
      end if;
    elsif to_integer(unsigned(f_exp)) - E_BIAS > 1022 then
      -- If the exponent is too large then we end up with a number that VHDL can't represent in a REAL.
      -- This gives fatal runtime errors.  Note that 1022 is used instead of 1023 (the actual max) because
      -- that allows us to ignore the value of the mantissa

      result := out_of_range;
    elsif to_integer(unsigned(f_exp)) - E_BIAS < -1021 then
      result := out_of_range;

    else
      -- not a special case
      result := normal;
    end if;

    return result;
  end function flt_to_special;

  -- Function to convert a std_logic_vector floating point representation into a real number
  function flt_to_real(f : std_logic_vector;  -- floating point number to convert
                       w, fw : integer)       -- total and fractional bit width of result
    return real is
    constant EW     : integer := w - fw;
    constant FW_LIM : integer := width_limit(fw);    -- limited internal value of fractional bit width
    constant E_BIAS : integer := 2 ** (EW - 1) - 1;
    constant ZEROS  : std_logic_vector(w-1 downto 0)    := (others => '0');
    variable f_int  : std_logic_vector(f'high downto 0) := f;  -- fixed width version of f
    variable f_sign : std_logic                         := f_int(w-1);              -- sign bit of f
    variable f_exp  : std_logic_vector(EW-1 downto 0)   := f_int(w-2 downto fw-1);  -- exponent of f
    variable f_mant : std_logic_vector(fw-2 downto 0)   := f_int(fw-2 downto 0);    -- mantissa of f
    variable exp    : integer;
    variable result : real;
  begin

    -- Check bit widths match
    assert f'high = w - 1
      report "ERROR: flt_to_real: input std_logic_vector f must have bit width = input integer w"
      severity failure;

    -- Check for special cases: return zero if any are found
    if flt_to_special(f, w, fw) /= normal then
      result := 0.0;
    else

      -- Convert mantissa to real
      -- To avoid VHDL's integer type overflowing, consider at most 30 bits of the mantissa
      result := real(to_integer(unsigned(f_mant(fw - 2 downto fw - FW_LIM)))) / real(2 ** (FW_LIM - 1)) + 1.0;

      -- Apply exponent
      exp := to_integer(unsigned(f_exp)) - E_BIAS;
      if exp > 0 then
        result := result * (2.0 ** real(exp));
      elsif exp < 0 then
        result := result / (2.0 ** real(-exp));
      end if;

      -- Apply sign bit
      if f_sign = '1' then
        result := -result;
      end if;

    end if;

    return result;
  end function flt_to_real;



  -- Function to return a  floating point number in std_logic_vector floating point representation.
  -- The number is the smallest normalised number that the Accumulator can accept, multiplied by 2^y
  --
  function get_smallest_flt_mult_2y (y       : natural;
                                    negative : boolean;            -- false = +ve, true = -ve
                                    s : floating_point_special_t   -- indicates special values to convert (overrides y)
                                    )
    return std_logic_vector is
    constant EW       : integer := 8;
    constant E_BIAS   : integer := 2 ** (EW - 1) - 1;
    variable result   : std_logic_vector(31 downto 0) := (others => '0');
    variable exp      : integer   := 0;
    variable min_biased_exp: integer := -32 + E_BIAS;
    variable max_biased_exp: integer := 16 + E_BIAS;
  begin
    -- Handle special cases
    case s is
      when zero_pos =>  -- plus zero
        result(31) := '0';                          -- sign bit clear
        result(30 downto 0) := (others => '0');     -- exponent and mantissa clear

      when zero_neg =>  -- minus zero
        result(31) := '1';                          -- sign bit set
        result(30 downto 0) := (others => '0');     -- exponent and mantissa clear

      when inf_pos =>   -- plus infinity
        result(31) := '0';                          -- sign bit clear
        result(30 downto 23) := (others => '1');  -- exponent
        result(22 downto 0)   := (others => '0');  -- mantissa

      when inf_neg =>   -- minus infinity
        result(31) := '1';                          -- sign bit set
        result(30 downto 23) := (others => '1');  -- exponent
        result(22 downto 0)   := (others => '0');  -- mantissa

      when nan =>       -- Not a Number
        result(31) := '0';                          -- sign bit
        result(30 downto 23) := (others => '1');  -- exponent
        result(22)            := '1';              -- MSB of mantissa set
        result(21 downto 0)   := (others => '0');  -- rest of mantissa clear

      -- NOTE: out_of_range might be possible under some circumstances, but it can be represented
      when normal | out_of_range =>
        -- Handle normal numbers
        if negative = true then
          result(31) := '1';
        else
          result(31) := '0';
        end if;

        -- Exponent.
        exp := min_biased_exp + y;

        -- Stop input overflows
        if exp > max_biased_exp then
          exp := max_biased_exp;
        end if;

        -- Bring exponent into normal range to allow valid IEEE representation
        if exp < 1 then
          exp := 1;
        end if;

        result(30 downto 23) := std_logic_vector(to_unsigned(exp, EW));

        -- Mantissa
        result(22 downto 0) := (others => '0');
      end case;
    return result;
  end function get_smallest_flt_mult_2y;
  -----------------------------------------------------------------------
  -- DUT signals
  -----------------------------------------------------------------------

  -- Global signals
  signal aclk                    : std_logic := '0';  -- the master clock
  signal aresetn                 : std_logic := '1';  -- synchronous active low reset

  -- A operand slave channel signals
  signal s_axis_a_tvalid         : std_logic := '0';  -- payload is valid
  signal s_axis_a_tready         : std_logic := '1';  -- slave is ready
  signal s_axis_a_tdata          : std_logic_vector(31 downto 0) := (others => '0');  -- data payload
  signal s_axis_a_tlast          : std_logic := '0';  -- indicates end of packet

  -- Result master channel signals
  signal m_axis_result_tvalid    : std_logic := '0';
  signal m_axis_result_tready    : std_logic := '1';
  signal m_axis_result_tdata     : std_logic_vector(31 downto 0) := (others => '0');  -- data payload
  signal m_axis_result_tlast     : std_logic := '0';  -- indicates end of packet

  -----------------------------------------------------------------------
  -- Aliases for AXI channel TDATA and TUSER fields
  -- These are a convenience for viewing data in a simulator waveform viewer.
  -- If using ModelSim or Questa, add "-voptargs=+acc=n" to the vsim command
  -- to prevent the simulator optimizing away these signals.
  -----------------------------------------------------------------------

  -- A operand slave channel alias signals
  signal s_axis_a_tdata_real    : real := 0.0;  -- floating-point value using VHDL 'real' data type
  signal s_axis_a_tdata_special : floating_point_special_t := normal;  -- indicate special values
  signal s_axis_a_tdata_sign    : std_logic := '0';  -- sign bit
  signal s_axis_a_tdata_exp     : std_logic_vector(7 downto 0) := (others => '0');  -- exponent (biased)
  signal s_axis_a_tdata_mant    : std_logic_vector(22 downto 0) := (others => '0');  -- mantissa (without hidden bit)



  -- Result master channel alias signals
  signal m_axis_result_tdata_real     : real := 0.0;  -- floating-point value using VHDL 'real' data type
  signal m_axis_result_tdata_special  : floating_point_special_t := normal;  -- indicate special values
  signal m_axis_result_tdata_sign     : std_logic := '0';  -- sign bit
  signal m_axis_result_tdata_exp     : std_logic_vector(7 downto 0) := (others => '0');  -- exponent (biased)
  signal m_axis_result_tdata_mant    : std_logic_vector(22 downto 0) := (others => '0');  -- mantissa (without hidden bit)

begin

  -----------------------------------------------------------------------
  -- Instantiate the DUT
  -----------------------------------------------------------------------

  dut : entity work.floating_point_4
    port map (
      -- Global signals
      aclk                    => aclk,
      aresetn                 => aresetn,
    -- AXI4-Stream slave channel for operand A
      s_axis_a_tvalid         => s_axis_a_tvalid,
      s_axis_a_tready         => s_axis_a_tready,
      s_axis_a_tdata          => s_axis_a_tdata,
      s_axis_a_tlast          => s_axis_a_tlast,
      -- AXI4-Stream master channel for output result
      m_axis_result_tvalid    => m_axis_result_tvalid,
      m_axis_result_tready    => m_axis_result_tready,
      m_axis_result_tdata     => m_axis_result_tdata,
      m_axis_result_tlast     => m_axis_result_tlast
      );


  -----------------------------------------------------------------------
  -- Generate clock
  -----------------------------------------------------------------------

  clock_gen : process
  begin
    aclk <= '0';
    wait for CLOCK_PERIOD;
    loop
      aclk <= '0';
      wait for CLOCK_PERIOD/2;
      aclk <= '1';
      wait for CLOCK_PERIOD/2;
    end loop;
  end process clock_gen;


  -----------------------------------------------------------------------
  -- Simulation control
  -- Run a series of demonstrations, each in a separate test phase
  -- This process controls all other stimuli processes
  -----------------------------------------------------------------------

  sim_control : process
  begin

    -- Drive simulation control synchronous to the rising edge of the clock
    wait until rising_edge(aclk);

    -- Run a single operation, and wait for the result
    sim_phase <= phase_single;

    wait for 25 * CLOCK_PERIOD + DUT_DELAY;
    -- Run a consecutive series of accumulations and wait for all results
    sim_phase <= phase_consecutive;
    wait for 105 * CLOCK_PERIOD + DUT_DELAY;


    -- Run the same consecutive series of accumulations, while demonstrating use and effect of AXI handshaking signals
    sim_phase <= phase_axi_handshake;
    wait for 132 * CLOCK_PERIOD;

    -- Start a consecutive series of operations, aborting it partway through using reset
    sim_phase <= phase_aresetn;
    wait for 12 * CLOCK_PERIOD;


    -- Run operations that demonstrate the use of special floating-point values (+/- zero, +/- infinity, Not a Number)
    sim_phase <= phase_special;
    wait for 100 * CLOCK_PERIOD;
    -- Allow operations in progress to complete and the results to be produced
    wait for DUT_DELAY;

    -- End of simulation
    report "Not a real failure. Simulation finished successfully. Test completed successfully" severity failure;
    wait;

  end process sim_control;


  -----------------------------------------------------------------------
  -- Generate inputs on the A operand slave channel
  -- This process also drives:
  -- + global synchronous reset input
  -- + RESULT master channel TREADY input
  -----------------------------------------------------------------------

  stimuli_a : process

    -- Procedure to drive a single transaction on the A channel
    procedure drive_a_single(tdata : std_logic_vector(31 downto 0);
                             tlast : std_logic;
                             variable abort : out boolean) is
    begin
      -- Drive AXI signals
      s_axis_a_tvalid <= '1';
      s_axis_a_tdata  <= tdata;
      s_axis_a_tlast  <= tlast;
      abort := false;
      loop
        wait until rising_edge(aclk);
        if aresetn = '0' then
          abort := true;
          exit;
        end if;
        exit when s_axis_a_tready = '1';
      end loop;
      wait for T_HOLD;
      s_axis_a_tvalid <= '0';
    end procedure drive_a_single;


    -- Procedure to drive a single value into the accumulator
    procedure accumulate(data      : std_logic_vector;
                         last      : std_logic
                         ) is
      variable tdata     : std_logic_vector(31 downto 0);
      variable tlast     : std_logic;
      variable abort     : boolean;
    begin

      -- Drive Data channel
      s_axis_a_tvalid <= '1';
      s_axis_a_tdata  <= data;
      s_axis_a_tlast  <= last;
      abort := false;
      loop
        wait until rising_edge(aclk);
        if aresetn = '0' then
          abort := true;
          exit;
        end if;
        exit when s_axis_a_tready = '1';
      end loop;
      wait for T_HOLD;
      s_axis_a_tvalid <= '0';
      s_axis_a_tlast <= '0';
    end procedure accumulate;




    variable tdata : std_logic_vector(31 downto 0) := (others => '0');
    variable tlast : std_logic := '1';
    variable abort : boolean;

  begin

    -- Wait for simulation control to signal the first phase
    wait until sim_phase = phase_single;
    wait for T_HOLD;  -- drive inputs T_HOLD after the rising edge of the clock




    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal),  '0');
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal),  '0');
    accumulate(get_smallest_flt_mult_2y (3, FALSE, normal),  '1');


    -- Wait for simulation control to signal the next phase
    wait until sim_phase = phase_consecutive;
    wait for T_HOLD;  -- drive inputs T_HOLD after the rising edge of the clock


    -- Run a series of back-to-back accumulations
    accumulate(get_smallest_flt_mult_2y (1,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (2,  FALSE, normal),   '1');

    accumulate(get_smallest_flt_mult_2y (3,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (4,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (5,  FALSE, normal),   '1');

    accumulate(get_smallest_flt_mult_2y (1,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (2,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (3,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (4,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (5,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (6,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (7,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (8,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (9,  FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (10, FALSE, normal),   '1');

    -- Wait for simulation control to signal the next phase
    wait until sim_phase = phase_axi_handshake;
    wait for T_HOLD;  -- drive inputs T_HOLD after the rising edge of the clock

    -- Run the same consecutive series of accumulations, while demonstrating use and effect of AXI handshaking signals
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal),   '0');
    -- No transactions for 5 clock cycles
    wait for 5 * CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal),   '1');


    accumulate(get_smallest_flt_mult_2y (3, FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (4, FALSE, normal),   '0');
    -- No transactions for 5 clock cycles
    wait for 5 * CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (5, FALSE, normal),   '1');

    -- Wait after every transaction
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (3, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (4, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (5, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (6, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (7, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (8, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (9, FALSE, normal),   '0');
    wait for CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (10, FALSE, normal),   '1');
    wait for CLOCK_PERIOD;

    -- Apply backpressure (not ready for result) for 50 clock cycles, then release
    m_axis_result_tready <= '0', '1' after 50 * CLOCK_PERIOD;


    -- Wait for simulation control to signal the next phase
    wait until sim_phase = phase_aresetn;
    wait for T_HOLD;  -- drive inputs T_HOLD after the rising edge of the clock

    -- Accumulate 10 values, but abort them partway through by asserting aresetn (active low)
    -- Note that aresetn must be asserted for at least 2 clock cycles (see core datasheet for details).

    aresetn <= '0' after 6 * CLOCK_PERIOD, '1' after 8 * CLOCK_PERIOD;
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (3, FALSE, normal),   '0');
    aresetn <= '0', '1' after 2 * CLOCK_PERIOD;
    -- Accumulation has aborted, so no need to send TLAST

    -- Wait for simulation control to signal the next phase
    wait until sim_phase = phase_special;
    wait for T_HOLD;  -- drive inputs T_HOLD after the rising edge of the clock

    -- Run operations that demonstrate the use of special floating-point values (+/- zero, +/- infinity, Not a Number)
    -- Accumulate a Nan.  Expect a Nan output but no exception flags
    --
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal),   '0');
    accumulate(get_smallest_flt_mult_2y (3, FALSE, nan   ),   '0');
    accumulate(get_smallest_flt_mult_2y (4, FALSE, normal),   '1');
    wait for 5 * CLOCK_PERIOD;

    -- Accumulate a single infinity.  Expect an equivalent infinity output but no exception flags
    --
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal ),   '0');
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal ),   '0');
    accumulate(get_smallest_flt_mult_2y (3, FALSE, inf_pos),   '0');
    accumulate(get_smallest_flt_mult_2y (4, FALSE, normal ),   '1');
    wait for 5 * CLOCK_PERIOD;

    -- Accumulate a + infinity and a - infinity.  Expect a NaN out and InvalidOp to be set.
    -- InvalidOp will remain set until the next accumulation begins
    --
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal ),   '0');
    accumulate(get_smallest_flt_mult_2y (2, FALSE, inf_neg),   '0');
    accumulate(get_smallest_flt_mult_2y (3, FALSE, inf_pos),   '0');
    accumulate(get_smallest_flt_mult_2y (4, FALSE, normal ),   '1');
    wait for 5 * CLOCK_PERIOD;

    -- Clear Invalid Op
    accumulate(get_smallest_flt_mult_2y (1, FALSE, normal),    '0');
    accumulate(get_smallest_flt_mult_2y (2, FALSE, normal),    '1');
    wait for 5 * CLOCK_PERIOD;
    -- End of test
    wait;

  end process stimuli_a;




  -----------------------------------------------------------------------
  -- Check outputs
  -----------------------------------------------------------------------

  check_outputs : process
    variable check_ok : boolean := true;
    -- Previous values of RESULT master channel signals
    variable result_tvalid_prev : std_logic := '0';
    variable result_tready_prev : std_logic := '1';
    variable result_tdata_prev  : std_logic_vector(31 downto 0) := (others => '0');
    variable result_tlast_prev  : std_logic := '0';
  begin

    -- Check outputs T_STROBE time after rising edge of clock
    wait until rising_edge(aclk);
    wait for T_STROBE;

    -- Do not check the output payload values, as this requires the behavioral model
    -- which would make this demonstration testbench unwieldy.
    -- Instead, check the protocol of the RESULT master channel:
    -- check that the payload is valid (not X) when TVALID is high
    -- and check that the payload does not change while TVALID is high until TREADY goes high

    if m_axis_result_tvalid = '1' and aresetn = '1' then
      if is_x(m_axis_result_tdata) then
        report "ERROR: m_axis_result_tdata is invalid when m_axis_result_tvalid is high" severity error;
        check_ok := false;
      end if;
      if is_x(m_axis_result_tlast) then
        report "ERROR: m_axis_result_tlast is invalid when m_axis_result_tvalid is high" severity error;
        check_ok := false;
      end if;

      if result_tvalid_prev = '1' and result_tready_prev = '0' then  -- payload must be the same as last cycle
        if m_axis_result_tdata /= result_tdata_prev then
          report "ERROR: m_axis_result_tdata changed while m_axis_result_tvalid was high and m_axis_result_tready was low" severity error;
          check_ok := false;
        end if;
        if m_axis_result_tlast /= result_tlast_prev then
          report "ERROR: m_axis_result_tlast changed while m_axis_result_tvalid was high and m_axis_result_tready was low" severity error;
          check_ok := false;
        end if;
      end if;

    end if;

    assert check_ok
      report "ERROR: terminating test with failures." severity failure;

    -- Record payload values for checking next clock cycle
    if check_ok then
      result_tvalid_prev := m_axis_result_tvalid;
      result_tready_prev := m_axis_result_tready;
      result_tdata_prev  := m_axis_result_tdata;
      result_tlast_prev  := m_axis_result_tlast;
    end if;

  end process check_outputs;


  -----------------------------------------------------------------------
  -- Assign TDATA / TUSER fields to aliases, for easy simulator waveform viewing
  -----------------------------------------------------------------------

  -- A operand slave channel alias signals
  s_axis_a_tdata_real    <= flt_to_real(s_axis_a_tdata(31 downto 0), 32, 24);
  s_axis_a_tdata_special <= flt_to_special(s_axis_a_tdata(31 downto 0), 32, 24);
  s_axis_a_tdata_sign    <= s_axis_a_tdata(31);
  s_axis_a_tdata_exp     <= s_axis_a_tdata(30 downto 23);
  s_axis_a_tdata_mant    <= s_axis_a_tdata(22 downto 0);

  -- Result master channel alias signals
  m_axis_result_tdata_real     <= flt_to_real(m_axis_result_tdata(31 downto 0), 32, 24) when m_axis_result_tvalid = '1';
  m_axis_result_tdata_special  <= flt_to_special(m_axis_result_tdata(31 downto 0), 32, 24) when m_axis_result_tvalid = '1';
  m_axis_result_tdata_sign     <= m_axis_result_tdata(31) when m_axis_result_tvalid = '1';
  m_axis_result_tdata_exp      <= m_axis_result_tdata(30 downto 23) when m_axis_result_tvalid = '1';
  m_axis_result_tdata_mant     <= m_axis_result_tdata(22 downto 0) when m_axis_result_tvalid = '1';

end tb;

