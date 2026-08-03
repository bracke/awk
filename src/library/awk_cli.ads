with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Awk_CLI is
   --  Testable top-level runner for the awk executable.
   --
   --  This package is internal CLI infrastructure. It is public only so the
   --  executable and AUnit harness can exercise the same code path; it is not
   --  a stable reusable library API.

   type Exit_Code is range 0 .. 255;

   type Invocation_Context is tagged limited private;
   --  Complete host invocation model used by the runner.

   --  @param Context Invocation context to populate from the process.
   procedure Initialize_From_Process (Context : in out Invocation_Context);

   --  @param Context Invocation context to reset.
   procedure Clear (Context : in out Invocation_Context);

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
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
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
   procedure Set_Standard_Output_Terminal (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether standard error should be treated as a terminal.
   procedure Set_Standard_Error_Terminal (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to update.
   --  @param Enabled Whether NO_COLOR or equivalent host policy is active.
   procedure Set_No_Color (Context : in out Invocation_Context; Enabled : Boolean);

   --  @param Context Invocation context to execute.
   --  @return Stable process exit code.
   function Run (Context : in out Invocation_Context) return Exit_Code;

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
   function Written_File_Name (Context : Invocation_Context; Index : Positive) return String;

   --  @param Context Invocation context to inspect.
   --  @param Index Captured write operation index.
   --  @return Exact content for captured write operation Index.
   function Written_File_Content (Context : Invocation_Context; Index : Positive) return String;

   --  @param Context Invocation context to inspect.
   --  @param Index Captured write operation index.
   --  @return True when captured write operation Index used append semantics.
   function Written_File_Append (Context : Invocation_Context; Index : Positive) return Boolean;

private
   package U renames Ada.Strings.Unbounded;

   type Virtual_File is record
      Path     : U.Unbounded_String;
      Content  : U.Unbounded_String;
      Readable : Boolean := True;
      Writable : Boolean := True;
      Openable : Boolean := True;
   end record;

   type Env_Item is record
      Name  : U.Unbounded_String;
      Value : U.Unbounded_String;
   end record;

   type Write_Operation is record
      Path    : U.Unbounded_String;
      Content : U.Unbounded_String;
      Append  : Boolean := False;
   end record;

   type Command_Output is record
      Command : U.Unbounded_String;
      Output  : U.Unbounded_String;
   end record;

   package File_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Virtual_File);
   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => U.Unbounded_String, "=" => U."=");
   package Env_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Env_Item);
   package Write_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Write_Operation);
   package Command_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Command_Output);

   type Invocation_Context is tagged limited record
      Arguments    : String_Vectors.Vector;
      Standard_In  : U.Unbounded_String;
      Locale       : U.Unbounded_String := U.To_Unbounded_String ("en");
      Catalog_Path : U.Unbounded_String := U.To_Unbounded_String ("resources/messages/catalog.txt");
      Files        : File_Vectors.Vector;
      Commands     : Command_Vectors.Vector;
      Environment  : Env_Vectors.Vector;
      Standard_Out : U.Unbounded_String;
      Standard_Err : U.Unbounded_String;
      Diagnostic_Set : Boolean := False;
      Diagnostic_Id       : U.Unbounded_String;
      Diagnostic_Category : U.Unbounded_String;
      Diagnostic_Severity : U.Unbounded_String;
      Writes       : Write_Vectors.Vector;
      Use_Process  : Boolean := False;
      Stdin_Fails  : Boolean := False;
      Stdout_Fails : Boolean := False;
      Stderr_Fails : Boolean := False;
      Stdout_Terminal : Boolean := False;
      Stderr_Terminal : Boolean := False;
      No_Color         : Boolean := False;
   end record;
end Awk_CLI;
