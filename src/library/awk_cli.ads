with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Awk_CLI is
   type Exit_Code is range 0 .. 255;

   type Invocation_Context is tagged limited private;

   procedure Initialize_From_Process (Context : in out Invocation_Context);
   procedure Clear (Context : in out Invocation_Context);
   procedure Add_Argument (Context : in out Invocation_Context; Value : String);
   procedure Set_Standard_Input (Context : in out Invocation_Context; Value : String);
   procedure Set_Locale (Context : in out Invocation_Context; Value : String);
   procedure Set_Catalog_Path (Context : in out Invocation_Context; Value : String);
   procedure Add_File
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
      Readable : Boolean := True;
      Writable : Boolean := True);
   procedure Add_Environment
     (Context : in out Invocation_Context;
      Name    : String;
      Value   : String);
   procedure Fail_Standard_Output (Context : in out Invocation_Context; Enabled : Boolean);
   procedure Fail_Standard_Error (Context : in out Invocation_Context; Enabled : Boolean);
   procedure Fail_Standard_Input (Context : in out Invocation_Context; Enabled : Boolean);

   function Run (Context : in out Invocation_Context) return Exit_Code;
   function Standard_Output (Context : Invocation_Context) return String;
   function Standard_Error (Context : Invocation_Context) return String;
   function Has_Diagnostic (Context : Invocation_Context) return Boolean;
   function Last_Diagnostic_Message_Id (Context : Invocation_Context) return String;
   function Last_Diagnostic_Category (Context : Invocation_Context) return String;
   function Last_Diagnostic_Severity (Context : Invocation_Context) return String;
   function Written_File_Count (Context : Invocation_Context) return Natural;
   function Written_File_Name (Context : Invocation_Context; Index : Positive) return String;
   function Written_File_Content (Context : Invocation_Context; Index : Positive) return String;
   function Written_File_Append (Context : Invocation_Context; Index : Positive) return Boolean;

private
   package U renames Ada.Strings.Unbounded;

   type Virtual_File is record
      Path     : U.Unbounded_String;
      Content  : U.Unbounded_String;
      Readable : Boolean := True;
      Writable : Boolean := True;
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

   package File_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Virtual_File);
   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => U.Unbounded_String, "=" => U."=");
   package Env_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Env_Item);
   package Write_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Write_Operation);

   type Invocation_Context is tagged limited record
      Arguments    : String_Vectors.Vector;
      Standard_In  : U.Unbounded_String;
      Locale       : U.Unbounded_String := U.To_Unbounded_String ("en");
      Catalog_Path : U.Unbounded_String := U.To_Unbounded_String ("resources/messages/catalog.txt");
      Files        : File_Vectors.Vector;
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
   end record;
end Awk_CLI;
