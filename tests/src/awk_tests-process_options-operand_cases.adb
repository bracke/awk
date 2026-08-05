with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Options.Operand_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Empty_Direct_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments := Arguments ([Argument ("")]);
   begin
      if not Project_Tools_Preserves_Empty_Arguments then
         return;
      end if;

      declare
         Result : constant Captured_Process := Run_Awk ("awk empty direct program", Args);
      begin
         Assert (Result.Status = 0, "empty direct program is passed to the interpreter");
         Assert (Output_String (Result) = "", "empty direct program writes no stdout");
      end;
   end Test_Process_Empty_Direct_Program;

   procedure Test_Process_Option_Terminator_Long_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments :=
        Arguments
          ([Argument ("--"),
            Argument ("BEGIN { print ARGV[1]; print ARGV[2]; print ARGV[3] }"),
            Argument ("--help"),
            Argument ("--version"),
            Argument ("--color=always")]);
      Result : constant Captured_Process := Run_Awk ("awk process terminator long operands", Args);
   begin
      Assert (Result.Status = 0, "option terminator long operands exit successfully");
      Assert
        (Project_Tools.Text.Contains
           (Output_String (Result),
            "--help" & LF & "--version" & LF & "--color=always" & LF),
         "long-option-looking values after -- remain AWK operands");
      Assert (not Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
              "--help after -- does not request help");
      Assert (not Project_Tools.Text.Contains
                (Output_String (Result),
                 English_Text ("awk.version.program", "version", "0.1.0")),
              "--version after -- does not request version output");
      Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "--color after -- does not style AWK output");
   end Test_Process_Option_Terminator_Long_Operands;

   procedure Test_Process_Awk_Output_Unstyled_With_Color_Always
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments :=
        Arguments
          ([Argument ("--color=always"),
            Argument ("BEGIN { print ""plain"" }")]);
      Result : constant Captured_Process := Run_Awk ("awk output color always", Args);
   begin
      Assert (Result.Status = 0, "process AWK output color always exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "plain" & LF), "AWK output is present");
      Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "color=always does not style AWK output");
   end Test_Process_Awk_Output_Unstyled_With_Color_Always;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Empty_Direct_Program'Access,
         "process empty direct program");
      Registration.Register_Routine
        (T, Test_Process_Option_Terminator_Long_Operands'Access,
         "process option terminator long operands");
      Registration.Register_Routine
        (T, Test_Process_Awk_Output_Unstyled_With_Color_Always'Access,
         "process AWK output color always");
   end Register;
end Awk_Tests.Process_Options.Operand_Cases;
