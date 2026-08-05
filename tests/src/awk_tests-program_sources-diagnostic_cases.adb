with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Options;
with Awk_CLI.Programs;
with Awk_Tests.Program_Sources.Support;

package body Awk_Tests.Program_Sources.Diagnostic_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   procedure Test_Program_File_Diagnostics_And_Display_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Open_Failed_Args : Opt.String_Vectors.Vector;
      Spaced_Args      : Opt.String_Vectors.Vector;
   begin
      Open_Failed_Args.Append (U.To_Unbounded_String ("-fmissing.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Open_Failed_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (not Source.Ok, "program file open failure is reported");
         Assert
           (U.To_String (Source.Diagnostic.Message_Id) = "awk.program_file.open_failed",
            "program source distinguishes open failure from read failure");
      end;

      Spaced_Args.Append (U.To_Unbounded_String ("-f"));
      Spaced_Args.Append (U.To_Unbounded_String ("space name.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Spaced_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (Source.Ok, "program file with spaces resolves");
         Assert
           (U.To_String (Source.Source.Text) = "  BEGIN { print ""spaced"" }  ",
            "program source is not normalized or rewritten");
         Assert
           (U.To_String (Source.Source.Segments.Element (1).Display_Name) =
            "space name.awk",
            "source segment display name preserves filename spelling");
      end;
   end Test_Program_File_Diagnostics_And_Display_Names;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Program_File_Diagnostics_And_Display_Names'Access,
         "program file diagnostics and display names");
   end Register;

end Awk_Tests.Program_Sources.Diagnostic_Cases;
