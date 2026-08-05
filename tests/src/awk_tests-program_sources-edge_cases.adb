with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;
with Awk_CLI.Programs;
with Awk_Tests.Program_Sources.Support;

package body Awk_Tests.Program_Sources.Edge_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;

   LF : constant String := [1 => ASCII.LF];

   procedure Test_Program_Source_Edges (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      File_Args   : Opt.String_Vectors.Vector;
      Direct_Args : Opt.String_Vectors.Vector;
      Failed_Args : Opt.String_Vectors.Vector;
   begin
      File_Args.Append (U.To_Unbounded_String ("-fempty.awk"));
      File_Args.Append (U.To_Unbounded_String ("-fnewline.awk"));
      File_Args.Append (U.To_Unbounded_String ("-ftail.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (File_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (Source.Ok, "edge source resolves");
         Assert
           (U.To_String (Source.Source.Text) =
            "BEGIN { print ""n"" }" & LF & "BEGIN { print ""tail"" }",
            "empty files do not add text and newline files do not get an extra separator");
         Assert (Source.Source.Segments.Length = 3, "empty segment is retained");
         Assert (Source.Source.Segments.Element (1).Start_Line = 1, "empty segment start");
         Assert (Source.Source.Segments.Element (1).End_Line = 0, "empty segment end");
         Assert (Source.Source.Segments.Element (2).Start_Line = 1, "newline segment start");
         Assert (Source.Source.Segments.Element (2).End_Line = 1, "newline segment end");
         Assert (Source.Source.Segments.Element (3).Start_Line = 2, "tail segment start");
      end;

      Direct_Args.Append (U.Null_Unbounded_String);
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Direct_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (Source.Ok, "empty direct program is valid source");
         Assert (U.To_String (Source.Source.Text) = "", "empty direct source preserved");
         Assert (Source.Source.Segments.Length = 1, "empty direct segment tracked");
         Assert
           (U.To_String (Source.Source.Segments.Element (1).Display_Name) =
            "awk.source.command_line",
            "direct source segment uses localized display-name key");
         Assert (Source.Source.Segments.Element (1).End_Line = 0, "empty direct has no source lines");
      end;

      Failed_Args.Append (U.To_Unbounded_String ("-fread-fails.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Failed_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve
             (Parsed.Options,
              Awk_Tests.Program_Sources.Support.Read_Test_File'Access);
      begin
         Assert (not Source.Ok, "program file read failure is reported");
         Assert
           (U.To_String (Source.Diagnostic.Message_Id) = "awk.program_file.read_failed",
            "program source distinguishes read failure from open failure");
      end;
   end Test_Program_Source_Edges;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Program_Source_Edges'Access, "program source edges");
   end Register;

end Awk_Tests.Program_Sources.Edge_Cases;
