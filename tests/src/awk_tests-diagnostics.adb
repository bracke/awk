with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Diagnostics;
with Awk_CLI.Localization;
with Awk_CLI.Output;

package body Awk_Tests.Diagnostics is
   use AUnit.Assertions;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk diagnostics");
   end Name;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Test_Context_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "usage error status");
      Assert (Awk_CLI.Standard_Output (Context) = "", "usage error does not write stdout");
      Assert (Awk_CLI.Standard_Error (Context)'Length > 0, "diagnostic is captured");
      Assert (Awk_CLI.Has_Diagnostic (Context), "structured diagnostic is captured");
      Assert
        (Awk_CLI.Last_Diagnostic_Message_Id (Context) = "awk.usage.unknown_option",
         "structured diagnostic message ID is retained");
      Assert (Awk_CLI.Last_Diagnostic_Category (Context) = "USAGE",
              "structured diagnostic category is retained");
      Assert (Awk_CLI.Last_Diagnostic_Severity (Context) = "ERROR",
              "structured diagnostic severity is retained");
   end Test_Context_Diagnostics;

   procedure Test_Context_Diagnostic_Sanitizing (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
      Escape  : constant String := [1 => Character'Val (27)];
   begin
      Awk_CLI.Add_Argument
        (Context, "--bad" & LF & "awk: error: forged" & Escape & "[2J");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "hostile option remains a usage error");
      Assert (not Contains (Awk_CLI.Standard_Error (Context), LF & "awk: error: forged"),
              "embedded newline cannot forge a diagnostic line");
      Assert (not Contains (Awk_CLI.Standard_Error (Context), Escape),
              "escape character is not emitted in diagnostics");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "\nawk: error: forged\e[2J"),
              "unsafe characters are rendered visibly");
   end Test_Context_Diagnostic_Sanitizing;

   procedure Test_Diagnostic_Source_Rendering (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Catalog : Awk_CLI.Localization.Catalog;
      Escape  : constant String := [1 => Character'Val (27)];
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, "../resources/messages/catalog.txt", "en");
      declare
         Item : constant Awk_CLI.Diagnostics.Diagnostic :=
           Awk_CLI.Diagnostics.With_Source
             (Awk_CLI.Diagnostics.Make
                ("awk.interpreter.parse_failed",
                 Awk_CLI.Diagnostics.Error,
                 Awk_CLI.Diagnostics.Interpreter,
                 Detail => "near print"),
              "bad" & LF & "file" & Escape & "[2J.awk",
              12,
              3);
         Text : constant String := Awk_CLI.Output.Diagnostic_Text (Catalog, Item, False);
      begin
         Assert (Contains (Text, "bad\nfile\e[2J.awk:12:3"),
                 "source location is escaped and compact");
         Assert (Contains (Text, "near print"), "technical detail is retained");
         Assert (not Contains (Text, Escape), "source rendering has no raw escape");
      end;
   end Test_Diagnostic_Source_Rendering;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Context_Diagnostics'Access, "context diagnostics");
      Registration.Register_Routine
        (T, Test_Context_Diagnostic_Sanitizing'Access,
         "context diagnostic sanitizing");
      Registration.Register_Routine
        (T, Test_Diagnostic_Source_Rendering'Access,
         "diagnostic source rendering");
   end Register_Tests;
end Awk_Tests.Diagnostics;
