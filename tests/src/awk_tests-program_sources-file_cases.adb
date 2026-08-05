with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;
with Awk_CLI.Programs;
with Awk_Tests.Program_Sources.Support;

package body Awk_Tests.Program_Sources.File_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;

   LF : constant String := [1 => ASCII.LF];

   procedure Test_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-f"));
      Args.Append (U.To_Unbounded_String ("a.awk"));
      Args.Append (U.To_Unbounded_String ("-fb.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (Source.Ok, "source resolves");
         Assert (U.To_String (Source.Source.Text) =
                 "BEGIN { print ""a"" }" & LF & "BEGIN { print ""b"" }",
                 "files are separated and ordered");
         Assert (Source.Source.Segments.Length = 2, "segments tracked");
         Assert (Source.Source.Segments.Element (1).Start_Line = 1, "first segment start");
         Assert (Source.Source.Segments.Element (1).End_Line = 1, "first segment end");
         Assert (Source.Source.Segments.Element (2).Start_Line = 2, "second segment start");
         Assert (Source.Source.Segments.Element (2).End_Line = 2, "second segment end");
      end;
   end Test_Program_Files;

   procedure Test_Program_File_Mode_Does_Not_Consume_Direct_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-fa.awk"));
      Args.Append (U.To_Unbounded_String ("{ print ""not source"" }"));
      Args.Append (U.To_Unbounded_String ("input"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (Source.Ok, "program-file mode source resolves");
         Assert (U.To_String (Source.Source.Text) = "BEGIN { print ""a"" }",
                 "-f source does not consume a direct program operand");
         Assert (Source.Source.Operands.Length = 2,
                 "remaining operands are both AWK operands");
         Assert
           (U.To_String (Source.Source.Operands.Element (1).Text) = "{ print ""not source"" }",
            "first remaining operand spelling is preserved");
      end;
   end Test_Program_File_Mode_Does_Not_Consume_Direct_Program;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Program_Files'Access, "program sources");
      Registration.Register_Routine
        (T, Test_Program_File_Mode_Does_Not_Consume_Direct_Program'Access,
         "program file mode operands");
   end Register;

end Awk_Tests.Program_Sources.File_Cases;
