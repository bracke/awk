with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;
with Awk_CLI.Platform;
with Awk_CLI.Programs;

package body Awk_Tests.Program_Sources is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;

   LF : constant String := [1 => ASCII.LF];

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk program sources");
   end Name;

   function Read_Test_File
     (Path : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      if Path = "a.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""a"" }");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "b.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""b"" }");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "empty.awk" then
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "newline.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""n"" }" & LF);
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "tail.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""tail"" }");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "space name.awk" then
         Content := U.To_Unbounded_String ("  BEGIN { print ""spaced"" }  ");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "read-fails.awk" then
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Read_Failed;
      else
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end if;
   end Read_Test_File;

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
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
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

   procedure Test_Program_Source_Edges (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      File_Args : Opt.String_Vectors.Vector;
      Direct_Args : Opt.String_Vectors.Vector;
      Failed_Args : Opt.String_Vectors.Vector;
   begin
      File_Args.Append (U.To_Unbounded_String ("-fempty.awk"));
      File_Args.Append (U.To_Unbounded_String ("-fnewline.awk"));
      File_Args.Append (U.To_Unbounded_String ("-ftail.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (File_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
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
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
      begin
         Assert (Source.Ok, "empty direct program is valid source");
         Assert (U.To_String (Source.Source.Text) = "", "empty direct source preserved");
         Assert (Source.Source.Segments.Length = 1, "empty direct segment tracked");
         Assert (Source.Source.Segments.Element (1).End_Line = 0, "empty direct has no source lines");
      end;

      Failed_Args.Append (U.To_Unbounded_String ("-fread-fails.awk"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Failed_Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
      begin
         Assert (not Source.Ok, "program file read failure is reported");
         Assert
           (U.To_String (Source.Diagnostic.Message_Id) = "awk.program_file.read_failed",
            "program source distinguishes read failure from open failure");
      end;
   end Test_Program_Source_Edges;

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
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
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
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
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
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
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

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Program_Files'Access, "program sources");
      Registration.Register_Routine (T, Test_Program_Source_Edges'Access, "program source edges");
      Registration.Register_Routine
        (T, Test_Program_File_Diagnostics_And_Display_Names'Access,
         "program file diagnostics and display names");
      Registration.Register_Routine
        (T, Test_Program_File_Mode_Does_Not_Consume_Direct_Program'Access,
         "program file mode operands");
   end Register_Tests;
end Awk_Tests.Program_Sources;
