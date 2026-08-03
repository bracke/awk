package Awk_CLI.Testing is
   --  In-memory invocation harness controls for AUnit and deterministic tests.

   --  @param Context Invocation context to update.
   --  @param Value Raw argument text to append.
   procedure Add_Argument (Context : in out Invocation_Context; Value : String);

   --  @param Context Invocation context to update.
   --  @param Value Complete standard-input text.
   procedure Set_Standard_Input (Context : in out Invocation_Context; Value : String);

   --  @param Context Invocation context to update.
   --  @param Value Locale name for CLI-owned text.
   procedure Set_Locale (Context : in out Invocation_Context; Value : String);

   --  @param Context Invocation context to update.
   --  @param Value Message catalog path.
   procedure Set_Catalog_Path (Context : in out Invocation_Context; Value : String);

   --  @param Context Invocation context to update.
   --  @param Path Virtual file path.
   --  @param Content Virtual file content.
   --  @param Readable Whether reads from the file succeed.
   --  @param Writable Whether writes to the file succeed.
   --  @param Openable Whether opening the file succeeds.
   procedure Add_File
     (Context  : in out Invocation_Context;
      Path     : String;
      Content  : String;
      Readable : Boolean := True;
      Writable : Boolean := True;
      Openable : Boolean := True);

   --  @param Context Invocation context to update.
   --  @param Command Command text to match.
   --  @param Output Deterministic command output.
   procedure Add_Command_Output
     (Context : in out Invocation_Context;
      Command : String;
      Output  : String);

   --  @param Context Invocation context to update.
   --  @param Name Environment variable name.
   --  @param Value Environment variable value.
   procedure Add_Environment
     (Context : in out Invocation_Context;
      Name    : String;
      Value   : String);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether standard-output writes should fail.
   procedure Fail_Standard_Output (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether standard-error writes should fail.
   procedure Fail_Standard_Error (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether standard-input reads should fail.
   procedure Fail_Standard_Input (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether standard output should be treated as a terminal.
   procedure Set_Standard_Output_Terminal
     (Context : in out Invocation_Context;
      Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether standard error should be treated as a terminal.
   procedure Set_Standard_Error_Terminal
     (Context : in out Invocation_Context;
      Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether NO_COLOR or equivalent host policy is active.
   procedure Set_No_Color (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to inspect.
   --  @return Captured standard output.
   function Standard_Output (Context : Invocation_Context) return String;

   --  @param Context Invocation context to inspect.
   --  @return Captured standard error.
   function Standard_Error (Context : Invocation_Context) return String;

   --  @param Context Invocation context to inspect.
   --  @return True when the last run recorded a structured diagnostic.
   function Has_Diagnostic (Context : Invocation_Context) return Boolean;

   --  @param Context Invocation context to inspect.
   --  @return Stable message ID of the last diagnostic, or an empty string.
   function Last_Diagnostic_Message_Id (Context : Invocation_Context) return String;

   --  @param Context Invocation context to inspect.
   --  @return Category name of the last diagnostic, or an empty string.
   function Last_Diagnostic_Category (Context : Invocation_Context) return String;

   --  @param Context Invocation context to inspect.
   --  @return Severity name of the last diagnostic, or an empty string.
   function Last_Diagnostic_Severity (Context : Invocation_Context) return String;

   --  @param Context Invocation context to inspect.
   --  @return Number of captured virtual file write operations.
   function Written_File_Count (Context : Invocation_Context) return Natural;

   --  @param Context Invocation context to inspect.
   --  @param Index Captured write operation index.
   --  @return Path for captured write operation Index.
   function Written_File_Name
     (Context : Invocation_Context;
      Index   : Positive) return String;

   --  @param Context Invocation context to inspect.
   --  @param Index Captured write operation index.
   --  @return Exact content for captured write operation Index.
   function Written_File_Content
     (Context : Invocation_Context;
      Index   : Positive) return String;

   --  @param Context Invocation context to inspect.
   --  @param Index Captured write operation index.
   --  @return True when captured write operation Index used append semantics.
   function Written_File_Append
     (Context : Invocation_Context;
      Index   : Positive) return Boolean;
end Awk_CLI.Testing;
