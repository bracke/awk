with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Execution;
with Awk_Tests.Support;

package body Awk_Tests.Redirections is
   use AUnit.Assertions;
   use Awk_Tests.Support;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk redirections");
   end Name;

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

   procedure Test_Context_Multiple_Redirections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { print ""a1"" > ""a.txt""; print ""b1"" > ""b.txt""; print ""a2"" > ""a.txt"" }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "multiple redirections succeed");
      Assert (Awk_CLI.Written_File_Count (Context) = 3,
              "awklib exposes live redirected writes");
      Assert (Awk_CLI.Written_File_Name (Context, 1) = "a.txt",
              "first redirection target is materialized first");
      Assert (Awk_CLI.Written_File_Content (Context, 1) = "a1" & LF,
              "first same-target write is exact");
      Assert (Awk_CLI.Written_File_Name (Context, 2) = "b.txt",
              "second redirection target is materialized second");
      Assert (Awk_CLI.Written_File_Content (Context, 2) = "b1" & LF,
              "second target content is exact");
      Assert (Awk_CLI.Written_File_Name (Context, 3) = "a.txt",
              "third write returns to first target");
      Assert (Awk_CLI.Written_File_Content (Context, 3) = "a2" & LF,
              "third write content is exact");
      Assert (Awk_CLI.Written_File_Append (Context, 3),
              "later writes to an open target append");
   end Test_Context_Multiple_Redirections;

   procedure Test_Context_Append_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""saved"" >> ""out.txt"" }");
      Awk_CLI.Add_File (Context, "out.txt", "old" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "append redirection run succeeds");
      Assert (Awk_CLI.Written_File_Count (Context) = 1, "one captured write recorded");
      Assert (Awk_CLI.Written_File_Name (Context, 1) = "out.txt", "redirection target");
      Assert (Awk_CLI.Written_File_Content (Context, 1) = "saved" & LF, "write content");
      Assert (Awk_CLI.Execution.Supports_Redirection_Append_Mode,
              "execution adapter exposes append-mode capability");
      Assert (Awk_CLI.Written_File_Append (Context, 1),
              "awklib streaming redirection exposes append intent");
      Assert (Awk_CLI.Written_File_Content (Context, 1) = "saved" & LF,
              "append write content is exact");
   end Test_Context_Append_Redirection;

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

   procedure Test_Context_Redirection_Fails_After_Partial_Materialization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { print ""ok"" > ""first.txt""; print ""blocked"" > ""second.txt""; print ""stdout"" }");
      Awk_CLI.Add_File (Context, "second.txt", "", Readable => True, Writable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "later redirection write failure is fatal");
      Assert (Awk_CLI.Written_File_Count (Context) = 1,
              "successful prior redirection write is recorded");
      Assert (Awk_CLI.Written_File_Name (Context, 1) = "first.txt",
              "prior redirection target is retained");
      Assert (Awk_CLI.Written_File_Content (Context, 1) = "ok" & LF,
              "prior redirection content is exact");
      Assert (Awk_CLI.Standard_Output (Context) = "",
              "stdout is not emitted after required redirection failure");
      Assert
        (Awk_CLI.Last_Diagnostic_Message_Id (Context) = "awk.output_file.write_failed",
         "structured diagnostic identifies later redirection write failure");
   end Test_Context_Redirection_Fails_After_Partial_Materialization;

   procedure Test_Context_Redirection_Open_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""x"" > ""out.txt"" }");
      Awk_CLI.Add_File
        (Context, "out.txt", "", Readable => True, Writable => True, Openable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "redirection open failure is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open output file"),
              "redirection open diagnostic is rendered");
      Assert
        (Awk_CLI.Last_Diagnostic_Message_Id (Context) = "awk.output_file.open_failed",
         "structured diagnostic identifies output open failure");
   end Test_Context_Redirection_Open_Failure;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Context_Redirection'Access, "context redirection");
      Registration.Register_Routine
        (T, Test_Context_Multiple_Redirections'Access,
         "context multiple redirections");
      Registration.Register_Routine
        (T, Test_Context_Append_Redirection'Access,
         "context append redirection");
      Registration.Register_Routine (T, Test_Context_Redirection_Failure'Access, "context redirection failure");
      Registration.Register_Routine
        (T, Test_Context_Redirection_Fails_After_Partial_Materialization'Access,
         "context redirection partial failure");
      Registration.Register_Routine
        (T, Test_Context_Redirection_Open_Failure'Access,
         "context redirection open failure");
   end Register_Tests;
end Awk_Tests.Redirections;
