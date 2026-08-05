with AUnit.Assertions;

with Awk_Tests.Process_Support;

package body Awk_Tests.Process_IO.Input_Cases.Stdin_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Explicit_Stdin_Eof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("{ print }"), Argument ("-")]);
      Result : constant Captured_Process := Run_Awk ("awk process explicit stdin eof", Args);
   begin
      Assert (Result.Status = 0, "explicit stdin operand accepts EOF");
      Assert (Output_String (Result) = "", "EOF stdin produces no records");
   end Test_Process_Explicit_Stdin_Eof;

   procedure Test_Process_Explicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("{ print NR "":"" $2 }"), Argument ("-")]);
      Result : constant Captured_Process :=
        Run_Awk_Err_To_Out (Args, "one two" & LF & "three four");
      Output : constant String := Output_String (Result);
   begin
      Assert (Result.Status = 0, "explicit stdin data exits successfully");
      Assert (Output = "1:two" & LF & "2:four",
              "process stdin data reaches installed executable");
   end Test_Process_Explicit_Stdin_Data;

   procedure Test_Process_Implicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("{ print NR "":"" $1 }")]);
      Result : constant Captured_Process :=
        Run_Awk_Err_To_Out (Args, "red blue" & LF & "green yellow");
      Output : constant String := Output_String (Result);
   begin
      Assert (Result.Status = 0, "implicit stdin data exits successfully");
      Assert (Output = "1:red" & LF & "2:green",
              "missing input operands read standard input at process boundary");
   end Test_Process_Implicit_Stdin_Data;

   procedure Test_Process_Repeated_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("{ print NR "":"" $0 }"),
            Argument ("-"),
            Argument ("-")]);
      Result : constant Captured_Process :=
        Run_Awk_Err_To_Out (Args, "alpha" & LF & "beta");
      Output : constant String := Output_String (Result);
   begin
      Assert (Result.Status = 0, "repeated stdin operands exit successfully");
      Assert (Output = "1:alpha" & LF & "2:beta",
              "first stdin operand consumes data and later stdin observes EOF");
   end Test_Process_Repeated_Stdin_Data;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Eof'Access,
         "process explicit stdin eof");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Data'Access,
         "process explicit stdin data");
      Registration.Register_Routine
        (T, Test_Process_Implicit_Stdin_Data'Access,
         "process implicit stdin data");
      Registration.Register_Routine
        (T, Test_Process_Repeated_Stdin_Data'Access,
         "process repeated stdin data");
   end Register;
end Awk_Tests.Process_IO.Input_Cases.Stdin_Cases;
