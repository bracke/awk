with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Failure_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Opt.Color_Mode;

   procedure Test_Option_Failures (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Failure (Argument, Message : String) is
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String (Argument));
         declare
            Result : constant Opt.Parse_Result := Opt.Parse (Args);
         begin
            Assert (not Result.Ok, Message);
         end;
      end Expect_Failure;
   begin
      Expect_Failure ("-F", "missing -F value rejected");
      Expect_Failure ("-v", "missing -v value rejected");
      Expect_Failure ("-f", "missing -f value rejected");
      Expect_Failure ("-v1bad=x", "invalid attached -v rejected");
      Expect_Failure ("-f-", "-f - rejected");
      Expect_Failure ("--color", "missing --color assignment rejected");
      Expect_Failure ("--color=", "empty --color mode rejected");
   end Test_Option_Failures;

   procedure Test_Option_Failure_Color_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Color
        (Arguments : Opt.String_Vectors.Vector;
         Expected  : Opt.Color_Mode;
         Message   : String)
      is
         Result : constant Opt.Parse_Result := Opt.Parse (Arguments);
      begin
         Assert (not Result.Ok, Message & " is a parse failure");
         Assert (Result.Color = Expected, Message & " preserves color mode");
      end Expect_Color;
   begin
      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--bad-option"));
         Expect_Color (Args, Opt.Color_Auto, "default-color unknown option");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=always"));
         Args.Append (U.To_Unbounded_String ("--bad-option"));
         Expect_Color (Args, Opt.Color_Always, "color=always unknown option");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=always"));
         Args.Append (U.To_Unbounded_String ("-F"));
         Expect_Color (Args, Opt.Color_Always, "color=always missing -F argument");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=never"));
         Args.Append (U.To_Unbounded_String ("-v1bad=x"));
         Expect_Color (Args, Opt.Color_Never, "color=never invalid assignment");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=always"));
         Args.Append (U.To_Unbounded_String ("-f-"));
         Expect_Color (Args, Opt.Color_Always, "color=always rejected stdin program file");
      end;

      declare
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String ("--color=never"));
         Expect_Color (Args, Opt.Color_Never, "color=never missing program");
      end;
   end Test_Option_Failure_Color_Preservation;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Option_Failures'Access, "option failures");
      Registration.Register_Routine
        (T, Test_Option_Failure_Color_Preservation'Access,
         "option failure color preservation");
   end Register;
end Awk_Tests.CLI_Options.Failure_Cases;
