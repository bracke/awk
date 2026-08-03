package Awk_Workflow_Message_Key_Policy is
   function First_Unknown_Production_Key_Literal
     (Root : String := "../src") return String;

   procedure Require_Production_Key_Literals
     (Root : String := "../src");
end Awk_Workflow_Message_Key_Policy;
