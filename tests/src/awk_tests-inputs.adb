with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Platform;
with Project_Tools.Text;

package body Awk_Tests.Inputs is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   LF : constant String := [1 => ASCII.LF];
   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Exit_Code;

   Read_Count : Natural := 0;

   function Read_Load_Test_File
     (Path : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      Read_Count := Read_Count + 1;
      if Path = "file.txt" then
         Content := U.To_Unbounded_String ("file" & LF);
         return Awk_CLI.Platform.Read_Success;
      else
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end if;
   end Read_Load_Test_File;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk inputs");
   end Name;

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
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "cannot read standard input"),
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
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "cannot open program file"),
              "program file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "unreadable.awk");
      Awk_CLI.Add_File (Context, "unreadable.awk", "", Readable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "unreadable program file is host I/O");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "cannot read program file"),
              "program file read diagnostic is rendered");
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
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "cannot open input file"),
              "input file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""begin"" } { print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "lazy missing input file is still host I/O");
      Assert (Awk_CLI.Standard_Output (Context) = "begin" & LF,
              "BEGIN output is emitted before lazy input open failure");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "cannot open input file"),
              "lazy input file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "unreadable.txt");
      Awk_CLI.Add_File (Context, "unreadable.txt", "", Readable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "unreadable input file is host I/O");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "cannot read input file"),
              "input file read diagnostic is rendered");
   end Test_Context_Input_File_Failure;

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

   procedure Test_Context_Assignment_Only_Uses_Implicit_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print FILENAME ""="" $0 }");
      Awk_CLI.Add_Argument (Context, "X=not-applied-by-cli");
      Awk_CLI.Set_Standard_Input (Context, "implicit" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "assignment-only operands still use implicit stdin");
      Assert (Awk_CLI.Standard_Output (Context) = "=implicit" & LF,
              "implicit stdin keeps awklib's empty FILENAME behavior");
   end Test_Context_Assignment_Only_Uses_Implicit_Stdin;

   procedure Test_Context_Mixed_Input_Order_And_Spelling
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print FILENAME "":"" FNR "":"" $0 }");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_Argument (Context, "dir/input name.txt");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_File (Context, "dir/input name.txt", "file one" & LF & "file two" & LF);
      Awk_CLI.Set_Standard_Input (Context, "stdin one" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "mixed stdin and named file input succeeds");
      Assert
        (Awk_CLI.Standard_Output (Context) =
           "-:1:stdin one" & LF &
           "dir/input name.txt:1:file one" & LF &
           "dir/input name.txt:2:file two" & LF,
         "input ordering and original filename spelling are preserved");
   end Test_Context_Mixed_Input_Order_And_Spelling;

   procedure Test_Load_Interspersed_Assignments_And_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Read_Count := 0;
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("A=1"), Original_Index => 2));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 3));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("file.txt"), Original_Index => 4));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("B=2"), Original_Index => 5));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 6));

      declare
         Classified : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Raw);
         Loaded : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load
             (Classified, "stdin" & LF, Read_Load_Test_File'Access);
      begin
         Assert (Loaded.Ok, "interspersed assignment input load succeeds");
         Assert (Loaded.Files.Length = 3,
                 "runtime assignments are not materialized as input streams");
         Assert (Read_Count = 1, "runtime assignments do not trigger file reads");
         Assert (U.To_String (Loaded.Files.Element (1).Name) = "-",
                 "first explicit stdin is retained");
         Assert (U.To_String (Loaded.Files.Element (1).Content) = "stdin" & LF,
                 "first explicit stdin consumes data");
         Assert (U.To_String (Loaded.Files.Element (2).Name) = "file.txt",
                 "named file remains ordered between stdin operands");
         Assert (U.To_String (Loaded.Files.Element (2).Content) = "file" & LF,
                 "named file content is loaded");
         Assert (U.To_String (Loaded.Files.Element (3).Name) = "-",
                 "second explicit stdin is retained");
         Assert (U.To_String (Loaded.Files.Element (3).Content) = "",
                 "second explicit stdin observes EOF");
      end;
   end Test_Load_Interspersed_Assignments_And_Stdin;

   procedure Test_Load_Assignment_Only_Implicit_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Read_Count := 0;
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("Only=assignment"), Original_Index => 2));

      declare
         Classified : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Raw);
         Loaded : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load
             (Classified, "implicit" & LF, Read_Load_Test_File'Access);
      begin
         Assert (Loaded.Ok, "assignment-only input load succeeds");
         Assert (Loaded.Files.Length = 1, "implicit stdin stream is added");
         Assert (Read_Count = 0, "assignment-only operands do not read files");
         Assert (U.To_String (Loaded.Files.Element (1).Name) = "",
                 "implicit stdin has empty awklib filename");
         Assert (U.To_String (Loaded.Files.Element (1).Content) = "implicit" & LF,
                 "implicit stdin content is loaded");
      end;
   end Test_Load_Assignment_Only_Implicit_Stdin;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Load_Interspersed_Assignments_And_Stdin'Access,
         "load interspersed assignments and stdin");
      Registration.Register_Routine
        (T, Test_Load_Assignment_Only_Implicit_Stdin'Access,
         "load assignment-only implicit stdin");
      Registration.Register_Routine
        (T, Test_Context_Standard_Input_Failure'Access,
         "context standard input failure");
      Registration.Register_Routine
        (T, Test_Context_Named_File_Does_Not_Read_Stdin'Access,
         "context named file skips stdin");
      Registration.Register_Routine
        (T, Test_Context_Program_File_Failure'Access,
         "context program file failure");
      Registration.Register_Routine
        (T, Test_Context_Input_File_Failure'Access,
         "context input file failure");
      Registration.Register_Routine
        (T, Test_Context_Repeated_Stdin'Access,
         "context repeated stdin");
      Registration.Register_Routine
        (T, Test_Context_Assignment_Only_Uses_Implicit_Stdin'Access,
         "context assignment-only implicit stdin");
      Registration.Register_Routine
        (T, Test_Context_Mixed_Input_Order_And_Spelling'Access,
         "context mixed input order and spelling");
   end Register_Tests;
end Awk_Tests.Inputs;
