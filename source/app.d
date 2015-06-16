import std.stdio, std.file, std.string, std.algorithm, std.getopt;
import kxml.xml;

string projectDirectory, projectFile;
bool waitUser, verbose;
static int[string] macrosList, spritesList, objectsList, scriptsList, fontsList;

static const int RESULT_OK = 0;
static const int RESULT_FILE_NOT_FOUND = 1;
static const int RESULT_TOO_MANY_FILES_IN_ROOT = 2;
static const int RESULT_PROJECT_NOT_FOUND = 3;
static const int RESULT_HELP = -1;

int main(string[] args)
{
    auto res = parseArguments(args);
    
    if (res == RESULT_OK)
    {
        createMacrosList(projectFile);
        searchMacrosInProject(projectDirectory, macrosList);
        
        displayUnusedMacros(macrosList);
    }
    
    if (waitUser)
    {
        writeln("\nPress Enter for exit...");
        readln();
    }
    
    return max(RESULT_OK, res);
}

int parseArguments(ref string[] args)
{
    getopt(args, "wait", &waitUser, "verbose", &verbose);
    
    /* Help */
    if (args.length != 2)
    {
        writeln("GMS-Macros 1.1");
        writeln("Tool for find unused GMS macros");
        writeln("15.06.2015, by Dmi7ry");
        writeln("http://github.com/dmi7ry/GMS-Macros\n");
        writeln("Usage:");
        writeln("  gms-macros.exe {options} <project directory>\n");
        writeln("  --wait\tWait user input before exit");
        writeln("  --verbose\tDisplay all checks");
        return RESULT_HELP;
    }
    
    /* Check command line arguments */
    auto project_dir = args[1];
    
    if (!project_dir.exists || !project_dir.isDir)
    {
        writeln("Error. Project directory not found: ", project_dir);
        return RESULT_FILE_NOT_FOUND;
    }

    projectDirectory = project_dir;
    
    /* Search project file */
    auto files = dirEntries(project_dir, "*.project.gmx", SpanMode.shallow);
    
    foreach(string f; files)
    {
        if (projectFile == "")
        {
            projectFile = f;
        }
        else
        {
            writeln("Error. Found more than one *.project.gmx file in the root directory of the project");
            return RESULT_TOO_MANY_FILES_IN_ROOT;
        } 
    }
    
    if (projectFile == "")
    {
        writeln("Error. Project file *.project.gmx not found");
        return RESULT_PROJECT_NOT_FOUND;
    }
    
    writeln("Project file: ", projectFile);
    
    return RESULT_OK;
}

/* Parse Project file */
void createMacrosList(string file)
{
    auto txt = readText(file);
    XmlNode project = readDocument(txt);
    auto constants = project.parseXPath("assets/constants/constant");
    foreach (val; constants)
    {
        auto name = val.getAttribute("name");
        macrosList[name] = 0;
    }
}

/* Parse Project directory */
void searchMacrosInProject(string dir, ref int[string] macros)
{
    auto files = dirEntries(dir ~ "\\scripts", "*.gml", SpanMode.depth);
    if (verbose) writeln("\nCheck scripts:");
    
    foreach(string f; files)
    {
        if (verbose) writeln("  ", f);
        parseScript(f, macros);
    }
    
    files = dirEntries(dir ~ "\\rooms", "*.room.gmx", SpanMode.depth);
    if (verbose) writeln("\nCheck rooms:");
    foreach(string f; files)
    {
        if (verbose) writeln("  ", f);
        parseRoom(f, macros);
    }
    
    files = dirEntries(dir ~ "\\objects", "*.object.gmx", SpanMode.depth);
    if (verbose) writeln("\nCheck objects:");
    foreach(string f; files)
    {
        if (verbose) writeln("  ", f);
        parseObject(f, macros);
    }
}

/* Check scripts */
void parseScript(string file, ref int[string] macros)
{
    auto txt = readText(file);
    
    foreach (string str; macros.keys)
    {
        if (indexOf(txt, str, true) != -1)
        {
            if (verbose) writeln("    found macros: ", str);
            macros[str]++;
        }
    }
}

/* Check rooms */
void parseRoom(string file, ref int[string] macros)
{
    auto txt = readText(file);
    
    XmlNode code = readDocument(txt);
    auto constants = code.parseXPath("room/code");
    
    foreach (XmlNode val; constants)
    {
        auto data = val.getCData;
        
        foreach (string str; macros.keys)
        {
            if (indexOf(data, str, true) != -1)
            {
                if (verbose) writeln("    found macros: ", str);
                macros[str]++;
            }
        }
    }
}

/* Check objects */
void parseObject(string file, ref int[string] macros)
{
    auto txt = readText(file);
    
    foreach (string str; macros.keys)
    {
        if (indexOf(txt, str, true) != -1)
        {
            if (verbose) writeln("    found macros: ", str);
            macros[str]++;
        }
    }
}

/* Display unused macros */
void displayUnusedMacros(ref int[string] macros)
{
    bool found;
    writeln("\nUnused macros:\n");
    foreach (string key; sort(macros.keys))
    {
        if (macros[key] == 0)
        {
            writeln(key);
            found = true;
        }
    }
    
    if (!found)
    {
        writeln("not found");
    }
}
