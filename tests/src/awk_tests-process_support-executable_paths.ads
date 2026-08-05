package Awk_Tests.Process_Support.Executable_Paths is
   function Awk_From_Repository_Root return String;
   function Awk_From_Tests_Directory return String;
   function Absolute_Awk_Path return String;
   function Preserves_Empty_Arguments return Boolean;
end Awk_Tests.Process_Support.Executable_Paths;
