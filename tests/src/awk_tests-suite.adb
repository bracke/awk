with AUnit.Assertions;
with AUnit.Test_Cases;

with Ada.Containers;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with Awk_CLI;
with Awk_CLI.Compatibility;
with Awk_CLI.Diagnostics;
with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Programs;
with Project_Tools.Processes;

package body Awk_Tests.Suite is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   LF : constant String := [1 => ASCII.LF];

   type CLI_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding procedure Register_Tests (T : in out CLI_Case);

   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Exit_Code;
   use type Awk_CLI.Diagnostics.Exit_Code;
   use type Awk_CLI.Operands.Operand_Kind;
   use type Opt.Color_Mode;

   overriding function Name (T : CLI_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk cli");
   end Name;

   function Read_Test_File (Path : String; Content : out U.Unbounded_String) return Boolean is
   begin
      if Path = "a.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""a"" }");
         return True;
      elsif Path = "b.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""b"" }");
         return True;
      elsif Path = "input" then
         Content := U.To_Unbounded_String ("x y" & LF);
         return True;
      else
         Content := U.Null_Unbounded_String;
         return False;
      end if;
   end Read_Test_File;

   function File_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : U.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         U.Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            U.Append (Result, LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return U.To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end File_Text;

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

   procedure Test_Options (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-F,"));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("name=a=b"));
      Args.Append (U.To_Unbounded_String ("{ print $1 }"));
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("-file"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "parse succeeds");
         Assert (Result.Options.Has_Field_Separator, "FS present");
         Assert (U.To_String (Result.Options.Field_Separator) = ",", "attached -F");
         Assert (Result.Options.Initial_Assignments.Length = 1, "-v retained");
         Assert (Result.Options.Operands.Length = 2, "operands retained after --");
      end;
   end Test_Options;

   procedure Test_Bad_Options (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("--color=sometimes"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (not Result.Ok, "bad color rejected");
         Assert (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) = Awk_CLI.Diagnostics.Usage_Exit,
                 "bad color is usage");
      end;
   end Test_Bad_Options;

   procedure Test_Option_Matrix (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-F"));
      Args.Append (U.To_Unbounded_String (":"));
      Args.Append (U.To_Unbounded_String ("-F,"));
      Args.Append (U.To_Unbounded_String ("-vempty="));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("path=a=b"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      Args.Append (U.To_Unbounded_String ("--color=never"));
      Args.Append (U.To_Unbounded_String ("{ print }"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "option matrix parses");
         Assert (U.To_String (Result.Options.Field_Separator) = ",", "final -F wins");
         Assert (Result.Options.Initial_Assignments.Length = 2, "both -v assignments retained");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (1).Name) = "empty",
                 "empty assignment name preserved");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (1).Value) = "",
                 "empty assignment value preserved");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (2).Value) = "a=b",
                 "multiple equals preserved in value");
         Assert (Result.Options.Color = Opt.Color_Never, "final color wins");
      end;
   end Test_Option_Matrix;

   procedure Test_Option_Failures (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Failure (Arg : String; Message : String) is
         Args : Opt.String_Vectors.Vector;
      begin
         Args.Append (U.To_Unbounded_String (Arg));
         declare
            Result : constant Opt.Parse_Result := Opt.Parse (Args);
         begin
            Assert (not Result.Ok, Message);
            Assert (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) = Awk_CLI.Diagnostics.Usage_Exit,
                    Message & " status");
         end;
      end Expect_Failure;
   begin
      Expect_Failure ("-F", "missing -F value rejected");
      Expect_Failure ("-v", "missing -v value rejected");
      Expect_Failure ("-f", "missing -f value rejected");
      Expect_Failure ("-v1bad=x", "invalid attached -v rejected");
      Expect_Failure ("-f-", "-f - rejected");
   end Test_Option_Failures;

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

   procedure Test_Operands (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("input"), Original_Index => 1));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 2));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("name=a=b"), Original_Index => 3));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("./X=value"), Original_Index => 4));
      declare
         Items : constant Awk_CLI.Operands.Operand_Vectors.Vector := Awk_CLI.Operands.Classify (Raw);
      begin
         Assert (Items.Element (1).Kind = Awk_CLI.Operands.Named_File, "file");
         Assert (Items.Element (2).Kind = Awk_CLI.Operands.Standard_Input, "stdin");
         Assert (Items.Element (3).Kind = Awk_CLI.Operands.Runtime_Assignment, "assignment");
         Assert (Items.Element (4).Kind = Awk_CLI.Operands.Named_File, "path with equals is file");
      end;
   end Test_Operands;

   procedure Test_Execution (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-vX=7"));
      Args.Append (U.To_Unbounded_String ("BEGIN { print X + 1 }"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "", Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute
             (U.To_String (Source.Source.Text), Parsed.Options, Ops, Input.Files, Env);
      begin
         Assert (Exec.Ok, "execution succeeds");
         Assert (U.To_String (Exec.Standard_Output) = "8" & LF, "-v visible before BEGIN");
      end;
   end Test_Execution;

   procedure Test_Context_Direct_Run (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print $2 }");
      Awk_CLI.Set_Standard_Input (Context, "one two" & LF & "three four" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "direct run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "two" & LF & "four" & LF,
              "stdout is captured exactly");
      Assert (Awk_CLI.Standard_Error (Context) = "", "no diagnostics");
   end Test_Context_Direct_Run;

   procedure Test_Context_File_Run (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "prog.awk");
      Awk_CLI.Add_Argument (Context, "input.txt");
      Awk_CLI.Add_File (Context, "prog.awk", "{ print FILENAME, FNR, $1 }");
      Awk_CLI.Add_File (Context, "input.txt", "alpha beta" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "file-backed run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "input.txt 1 alpha" & LF,
              "virtual file input reaches awklib");
   end Test_Context_File_Run;

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

   procedure Test_Context_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""saved"" > ""out.txt"" }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "redirection run succeeds");
      Assert (Awk_CLI.Written_File_Count (Context) = 1, "one redirected file written");
      Assert (Awk_CLI.Written_File_Name (Context, 1) = "out.txt", "redirection target");
      Assert (Awk_CLI.Written_File_Content (Context, 1) = "saved" & LF, "redirection content");
      Assert (not Awk_CLI.Written_File_Append (Context, 1), "overwrite redirection is recorded");
      Assert (Awk_CLI.Standard_Output (Context) = "", "redirected output not sent to stdout");
   end Test_Context_Redirection;

   procedure Test_Context_Append_Redirection_Limitation (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""saved"" >> ""out.txt"" }");
      Awk_CLI.Add_File (Context, "out.txt", "old" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "append redirection run succeeds");
      Assert (Awk_CLI.Written_File_Count (Context) = 1, "one captured write recorded");
      Assert (Awk_CLI.Written_File_Name (Context, 1) = "out.txt", "captured redirection target");
      Assert (Awk_CLI.Written_File_Content (Context, 1) = "saved" & LF, "captured write content");
      Assert (not Awk_CLI.Written_File_Append (Context, 1),
              "AWK-COMPAT-REDIRECTION-001: awklib does not expose append intent");
   end Test_Context_Append_Redirection_Limitation;

   procedure Test_Context_Output_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""x"" }");
      Awk_CLI.Fail_Standard_Output (Context, True);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "stdout failure is host I/O");
   end Test_Context_Output_Failure;

   procedure Test_Context_Standard_Input_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Fail_Standard_Input (Context, True);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "stdin failure is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read standard input"),
              "stdin diagnostic is rendered");
   end Test_Context_Standard_Input_Failure;

   procedure Test_Context_Named_File_Does_Not_Read_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print $1 }");
      Awk_CLI.Add_Argument (Context, "input.txt");
      Awk_CLI.Add_File (Context, "input.txt", "file data" & LF);
      Awk_CLI.Fail_Standard_Input (Context, True);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "named-file input does not require stdin");
      Assert (Awk_CLI.Standard_Output (Context) = "file" & LF,
              "named-file input still reaches awklib");
   end Test_Context_Named_File_Does_Not_Read_Stdin;

   procedure Test_Context_Program_File_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "missing.awk");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "missing program file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read program file"),
              "program file diagnostic is rendered");
   end Test_Context_Program_File_Failure;

   procedure Test_Context_Input_File_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "missing input file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read input file"),
              "input file diagnostic is rendered");
   end Test_Context_Input_File_Failure;

   procedure Test_Context_Redirection_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""x"" > ""out.txt"" }");
      Awk_CLI.Add_File (Context, "out.txt", "", Readable => True, Writable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "redirection write failure is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot write output file"),
              "redirection diagnostic is rendered");
   end Test_Context_Redirection_Failure;

   procedure Test_Context_Stderr_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Fail_Standard_Error (Context, True);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "diagnostic stderr failure is host I/O");
      Assert (Awk_CLI.Standard_Error (Context) = "", "failed stderr is not reported as written");
   end Test_Context_Stderr_Failure;

   procedure Test_Context_Environment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ENVIRON[""AWK_TEST_ENV""] }");
      Awk_CLI.Add_Environment (Context, "AWK_TEST_ENV", "present");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "environment run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "present" & LF,
              "environment entry reaches awklib");
   end Test_Context_Environment;

   procedure Test_Context_Argv_Argc (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { print ARGC; print ARGV[0]; print ARGV[1]; print ARGV[2]; print ARGV[3] }");
      Awk_CLI.Add_Argument (Context, "input.txt");
      Awk_CLI.Add_Argument (Context, "name=value");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_File (Context, "input.txt", "ignored" & LF);
      Awk_CLI.Set_Standard_Input (Context, "stdin" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "ARGV/ARGC run succeeds");
      Assert
        (Awk_CLI.Standard_Output (Context) =
           "4" & LF & "awk" & LF & "input.txt" & LF & "name=value" & LF & "-" & LF,
         "ARGV preserves operand spelling and order");
   end Test_Context_Argv_Argc;

   procedure Test_Context_Repeated_Stdin (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print FILENAME ""="" $0 }");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Set_Standard_Input (Context, "one" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "repeated stdin succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "-=one" & LF,
              "second stdin operand observes end of file");
   end Test_Context_Repeated_Stdin;

   procedure Test_Compatibility_Registry (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Docs : constant String := File_Text ("../docs/compatibility.md");
   begin
      Assert (Awk_CLI.Compatibility.Count >= 7, "registry has accepted limitation entries");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-REGEX-001"), "regex ID present");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-GETLINE-001"), "getline BEGIN ID present");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-GETLINE-002"), "pipe getline ID present");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-UTF8-001"), "UTF-8 ID present");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-PRINTF-001"), "printf ID present");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-ASSIGNMENT-001"), "assignment ID present");
      Assert (Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-REDIRECTION-001"), "redirection ID present");

      for Index in 1 .. Awk_CLI.Compatibility.Count loop
         Assert (Contains (Docs, Awk_CLI.Compatibility.Id (Index)),
                 "documented registry ID: " & Awk_CLI.Compatibility.Id (Index));
         Assert (Awk_CLI.Compatibility.Documentation (Index) = "docs/compatibility.md",
                 "registry documentation path is stable");
      end loop;
   end Test_Compatibility_Registry;

   procedure Test_Catalog_Key_Coverage (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Catalog : constant String := File_Text ("../resources/messages/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Assert (Contains (Catalog, Key & " ="), "catalog contains " & Key);
      end Require_Key;
   begin
      Require_Key ("en.awk.help.title");
      Require_Key ("en.awk.help.summary");
      Require_Key ("en.awk.usage.missing_program");
      Require_Key ("en.awk.usage.unknown_option");
      Require_Key ("en.awk.interpreter.runtime_failed");
      Require_Key ("en.awk.standard_output.write_failed");
      Require_Key ("da.awk.help.title");
      Require_Key ("da.awk.help.summary");
      Require_Key ("da.awk.usage.missing_program");
      Require_Key ("da.awk.usage.unknown_option");
      Require_Key ("da.awk.interpreter.runtime_failed");
      Require_Key ("da.awk.standard_output.write_failed");
   end Test_Catalog_Key_Coverage;

   procedure Test_Localized_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "Danish usage error status");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "ukendt tilvalg"),
              "Danish diagnostic is selected");
   end Test_Localized_Diagnostics;

   procedure Test_Awk_Output_Unchanged_By_Locale (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""not localized"" }");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "localized context execution succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "not localized" & LF,
              "AWK output is not localized");
   end Test_Awk_Output_Unchanged_By_Locale;

   procedure Test_Process_Version (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--version")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk --version",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process version exits successfully");
      Assert (Contains (U.To_String (Output), "awk 0.1.0"), "process version includes awk version");
      Assert (Contains (U.To_String (Output), "awklib 0.1.0"), "process version includes awklib version");
   end Test_Process_Version;

   procedure Test_Process_Direct_File_Input (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk direct file input",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process direct file input exits successfully");
      Assert (U.To_String (Output) = "two" & LF & "four" & LF & LF,
              "process direct file input output");
   end Test_Process_Direct_File_Input;

   procedure Test_Process_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 6) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/begin.awk"),
         new String'("-ftests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("name=value")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -f",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -f exits successfully");
      Assert (Contains (U.To_String (Output), "begin" & LF & "one" & LF & "three"),
              "process -f loads files in order and reads first input");
      Assert (Contains (U.To_String (Output), "five" & LF),
              "process -f reads second input after runtime assignment operand");
   end Test_Process_Program_Files;

   procedure Test_Process_Help_Color_Never (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=never"), new String'("--help")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help no color",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process help exits successfully");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=never suppresses ANSI escapes");
   end Test_Process_Help_Color_Never;

   procedure Test_Process_Help_Color_Always (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=always"), new String'("--help")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help color always",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process help color always exits successfully");
      Assert (Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always styles CLI-owned help");
   end Test_Process_Help_Color_Always;

   procedure Test_Process_Awk_Output_Unstyled_With_Color_Always
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""plain"" }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk output color always",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process AWK output color always exits successfully");
      Assert (Contains (U.To_String (Output), "plain" & LF), "AWK output is present");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always does not style AWK output");
   end Test_Process_Awk_Output_Unstyled_With_Color_Always;

   procedure Test_Process_Usage_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad-option")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk usage failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 2, "unknown option exits with usage status");
   end Test_Process_Usage_Status;

   procedure Test_Process_Missing_Program_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk missing program file",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 3, "missing process program file exits with host I/O status");
      Assert (U.To_String (Output) = "", "missing process program file writes no stdout");
   end Test_Process_Missing_Program_File;

   procedure Test_Process_Missing_Input_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("tests/fixtures/input/no-such-input.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk missing input file",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 3, "missing process input file exits with host I/O status");
      Assert (U.To_String (Output) = "", "missing process input file writes no stdout");
   end Test_Process_Missing_Input_File;

   procedure Test_Process_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_redir.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print ""saved"" > """ & Target & """ }")];
      Status : Integer;
   begin
      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;

      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process redirection",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);

      Assert (Status = 0, "process redirection exits successfully");
      Assert (U.To_String (Output) = "", "process redirected output not on stdout");
      Assert (File_Text ("../" & Target) = "saved", "process redirection file content");

      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;
   end Test_Process_Redirection;

   procedure Test_Process_Field_Separator (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("-F"),
         new String'(" "),
         new String'("{ print $1 ""/"" $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -F",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -F exits successfully");
      Assert (Contains (U.To_String (Output), "one/two" & LF & "three/four"),
              "process -F splits fields");
   end Test_Process_Field_Separator;

   procedure Test_Process_V_Assignment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-vX=41"),
         new String'("BEGIN { print X + 1 }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -v",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -v exits successfully");
      Assert (Contains (U.To_String (Output), "42" & LF), "process -v is visible before BEGIN");
   end Test_Process_V_Assignment;

   procedure Test_Process_Parse_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN {")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process parse failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 1, "process parse failure exits with interpreter status");
      Assert (U.To_String (Output) = "", "parse failure does not write stdout");
   end Test_Process_Parse_Failure;

   procedure Test_Process_Multiple_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("{ print FILENAME "":"" FNR "":"" $1 }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process multiple files",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process multiple files exits successfully");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/basic.txt:1:one"),
              "first file FILENAME/FNR visible");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/second.txt:1:five"),
              "second file FILENAME/FNR visible");
   end Test_Process_Multiple_Files;

   overriding procedure Register_Tests (T : in out CLI_Case) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Options'Access, "option parser");
      Registration.Register_Routine (T, Test_Bad_Options'Access, "usage diagnostics");
      Registration.Register_Routine (T, Test_Option_Matrix'Access, "option matrix");
      Registration.Register_Routine (T, Test_Option_Failures'Access, "option failures");
      Registration.Register_Routine (T, Test_Program_Files'Access, "program sources");
      Registration.Register_Routine (T, Test_Operands'Access, "operand classifier");
      Registration.Register_Routine (T, Test_Execution'Access, "awklib execution adapter");
      Registration.Register_Routine (T, Test_Context_Direct_Run'Access, "context direct run");
      Registration.Register_Routine (T, Test_Context_File_Run'Access, "context file run");
      Registration.Register_Routine (T, Test_Context_Diagnostics'Access, "context diagnostics");
      Registration.Register_Routine
        (T, Test_Context_Diagnostic_Sanitizing'Access,
         "context diagnostic sanitizing");
      Registration.Register_Routine (T, Test_Context_Redirection'Access, "context redirection");
      Registration.Register_Routine
        (T, Test_Context_Append_Redirection_Limitation'Access,
         "context append redirection limitation");
      Registration.Register_Routine (T, Test_Context_Output_Failure'Access, "context output failure");
      Registration.Register_Routine
        (T, Test_Context_Standard_Input_Failure'Access,
         "context standard input failure");
      Registration.Register_Routine
        (T, Test_Context_Named_File_Does_Not_Read_Stdin'Access,
         "context named file skips stdin");
      Registration.Register_Routine (T, Test_Context_Program_File_Failure'Access, "context program file failure");
      Registration.Register_Routine (T, Test_Context_Input_File_Failure'Access, "context input file failure");
      Registration.Register_Routine (T, Test_Context_Redirection_Failure'Access, "context redirection failure");
      Registration.Register_Routine (T, Test_Context_Stderr_Failure'Access, "context stderr failure");
      Registration.Register_Routine (T, Test_Context_Environment'Access, "context environment");
      Registration.Register_Routine (T, Test_Context_Argv_Argc'Access, "context ARGV/ARGC");
      Registration.Register_Routine (T, Test_Context_Repeated_Stdin'Access, "context repeated stdin");
      Registration.Register_Routine (T, Test_Compatibility_Registry'Access, "compatibility registry");
      Registration.Register_Routine (T, Test_Catalog_Key_Coverage'Access, "catalog key coverage");
      Registration.Register_Routine (T, Test_Localized_Diagnostics'Access, "localized diagnostics");
      Registration.Register_Routine (T, Test_Awk_Output_Unchanged_By_Locale'Access, "AWK output locale separation");
      Registration.Register_Routine (T, Test_Process_Version'Access, "process version");
      Registration.Register_Routine (T, Test_Process_Direct_File_Input'Access, "process direct file input");
      Registration.Register_Routine (T, Test_Process_Program_Files'Access, "process -f program files");
      Registration.Register_Routine (T, Test_Process_Help_Color_Never'Access, "process help color never");
      Registration.Register_Routine (T, Test_Process_Help_Color_Always'Access, "process help color always");
      Registration.Register_Routine
        (T, Test_Process_Awk_Output_Unstyled_With_Color_Always'Access,
         "process AWK output color always");
      Registration.Register_Routine (T, Test_Process_Usage_Status'Access, "process usage status");
      Registration.Register_Routine
        (T, Test_Process_Missing_Program_File'Access,
         "process missing program file");
      Registration.Register_Routine
        (T, Test_Process_Missing_Input_File'Access,
         "process missing input file");
      Registration.Register_Routine (T, Test_Process_Redirection'Access, "process redirection");
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine (T, Test_Process_Multiple_Files'Access, "process multiple files");
   end Register_Tests;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
   begin
      Result.Add_Test (new CLI_Case);
      return Result;
   end Suite;
end Awk_Tests.Suite;
