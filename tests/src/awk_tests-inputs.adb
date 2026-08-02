with AUnit.Assertions;

with Awk_CLI;
with Awk_Tests.Support;

package body Awk_Tests.Inputs is
   use AUnit.Assertions;
   use Awk_Tests.Support;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

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
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open program file"),
              "program file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "unreadable.awk");
      Awk_CLI.Add_File (Context, "unreadable.awk", "", Readable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "unreadable program file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read program file"),
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
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open input file"),
              "input file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""begin"" } { print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "lazy missing input file is still host I/O");
      Assert (Awk_CLI.Standard_Output (Context) = "begin" & LF,
              "BEGIN output is emitted before lazy input open failure");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open input file"),
              "lazy input file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "unreadable.txt");
      Awk_CLI.Add_File (Context, "unreadable.txt", "", Readable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "unreadable input file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read input file"),
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

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
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
