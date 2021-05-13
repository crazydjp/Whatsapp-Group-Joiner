#include <amxmodx>

#define PLUGIN "Whatsapp_Group_Request"
#define VERSION "3.2"
#define AUTHOR "CrAzY MaN"

#define FLAG_VIEW ADMIN_BAN
#define FLAG_DELETE ADMIN_CVAR

#if AMXX_VERSION_NUM < 183
	#define MAX_PLAYERS 32
#endif

new const xPrefix[] = "!g[Whatsapp Group]!n";

new const gBlockTexts[][] =
{
	"`",
	"~",
	"!",
	"@",
	"#",
	"$",
	"%",
	"^^",
	"&",
	"*",
	"(",
	")",
	"-",
	"_",
	"=",
	"[",
	"]",
	"{",
	"}",
	"\",
	"|",
	";",
	":",
	" ",
	"'",
	"^"",
	",",
	".",
	"<",
	">",
	"/",
	"?"
};

new iRequestsFile[50], g_iSayText, bool:gAdded[MAX_PLAYERS + 1]
new c_number_digits, c_countrycode_digits, min_digit, max_digit;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar(PLUGIN, VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	
	register_clcmd("say /whatsapp", "MainMenu");
	register_clcmd("say whatsapp", "MainMenu");
	
	c_number_digits = register_cvar("Country Number Digits", "10");
	c_countrycode_digits = register_cvar("Country Code Digits", "2");
	
	min_digit = get_pcvar_num(c_number_digits);
	max_digit = min_digit + get_pcvar_num(c_countrycode_digits) + 1;
	
	register_dictionary("whatsapp_group_request.txt");
	
	register_concmd("Type_Your_Whatsapp_Number", "Request_To_Add"); //REQUESTING TO ADD
	register_concmd("Type_Your_New_Number", "Update_Number"); //UPDATE YOUR NUMBER
	
	g_iSayText = get_user_msgid("SayText");
	
	//YOU CAN SEE REQUESTS IN THIS FILE
	formatex(iRequestsFile, charsmax(iRequestsFile), "addons/amxmodx/configs/whatsapp_group_request.ini");
}

public client_putinserver(id)
	check_isAdded(id);
	
public check_isAdded(id)
{
	new szName[32], szData[128], file;
	get_user_name(id, szName, charsmax(szName));
	
	if(file_exists(iRequestsFile))
	{
		file = fopen(iRequestsFile, "rt");
		
		while(!feof(file))
		{
			fgets(file, szData, charsmax(szData));
			
			if(equali(szData[10], szName, strlen(szName)))
				gAdded[id] = true;
				
			break;
		}
		fclose(file);
	}
}

public MainMenu(id)
{
	new menu;
	if(gAdded[id] == false)
	{
		menu = menu_create("\wWant to \rjoin \wour \yWhatsapp Group\w?", "main_menu_handler");
		menu_additem(menu, "Yes", "0"); //case 0	
	}
	else
	{
		menu = menu_create("\wWant to \rupdate \wour \yrequested number\w?", "main_menu_handler");
		menu_additem(menu, "Update Number", "0"); //case 1
	}
	menu_additem(menu, "No", "1"); //case 3
	if(get_user_flags(id) & FLAG_VIEW)
		menu_additem(menu, "\yView Requests", "2"); //case 3
	if(get_user_flags(id) & FLAG_DELETE)
		menu_additem(menu, "\rDelete Requests", "3"); //case 4

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER); // REMOVES EXIT BUTTON FROM MENU
	
	menu_display(id, menu);
}

public main_menu_handler(id, menu, item)	
{
	switch(item)
	{
		//YES / UPDATE
		case 0 : {
				if(gAdded[id] == false)
				{
					client_cmd(id, "messagemode Type_Your_Whatsapp_Number");
					ColorChat(id, "%L",LANG_PLAYER, "ENTER_NUM");
				}
				else
				{
					client_cmd(id, "messagemode Type_Your_New_Number");
					ColorChat(id, "%L",LANG_PLAYER, "ENTER_NEW_NUM");
				}
			}
		//NO
		case 1 : {
				
				ColorChat(id, "%L",LANG_PLAYER, "DENIED");
				client_cmd(id, "spk fvox/deactivated.wav");
			}
		//VIEW REQUESTS	
		case 2 : {
				ColorChat(id, "%L", LANG_PLAYER, "VIEW_REQUESTS");
				View_Requests(id);
			}
		//DELETE REQUESTS
		case 3 : {	
				new submenu = menu_create("\wAre you \ysure \wyou want to \rdelete requests?", "delete_request_handler");
				
				menu_additem(submenu, "Yes", "0");
				menu_additem(submenu, "No", "1");
				
				menu_setprop(submenu, MPROP_EXIT, MEXIT_NEVER); // REMOVES EXIT BUTTON FROM MENU
				menu_display(id, submenu);
			}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
	
public Request_To_Add(id)
{
	new Number[16], szName[32], szAuthID[32], szData[128], file, i;
	
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuthID, charsmax(szAuthID));
	
	if(gAdded[id] == true)
		return PLUGIN_HANDLED;
	
	read_argv(1, Number, 15);
	
	//CHECKS IF NUMBER IS CORRECT OR NOT
	for(i = 0; i < sizeof(gBlockTexts); i++)
	{ 
		if(containi(Number, gBlockTexts[i]) != -1) 
		{ 
			ColorChat(id, "%L",LANG_PLAYER, "WRONG_NUM");
			client_cmd(id, "spk buttons/button10.wav");
			return PLUGIN_HANDLED;
		} 
	} 
    
	for(i = 0; i <= strlen(Number); i++)
	{
		if(isalpha(Number[i]))
		{
				ColorChat(id, "%L",LANG_PLAYER, "WRONG_NUM");
				client_cmd(id, "spk buttons/button10.wav");
				return PLUGIN_HANDLED;
		}
	}
	
	if((strlen(Number) < min_digit) || (strlen(Number) > max_digit) || ((Number[0] == '+')  && (strlen(Number) < max_digit)) || ((Number[0] != '+') && (strlen(Number) > min_digit)))
	{
		ColorChat(id, "%L",LANG_PLAYER, "WRONG_NUM");
		client_cmd(id, "spk buttons/button10.wav");
		return PLUGIN_HANDLED;
	}
	
	file = fopen(iRequestsFile, "at");
	
	//FORMAT IN THE FILE
	formatex(szData, charsmax(szData), "[REQUEST] %s(%s) : %s^n", szName, szAuthID, Number);
	fputs(file, szData);
	fclose(file);
	
	ColorChat(id, "%L",LANG_PLAYER, "NUM_ADDED_MSG_PLAYER");
	ColorChat(0, "%L", LANG_PLAYER, "NUM_ADDED_MSG_ALL1", szName);
	ColorChat(0, "%L",LANG_PLAYER, "NUM_ADDED_MSG_ALL2");
	
	client_cmd(0, "spk vox/accepted.wav");
	
	check_isAdded(id);
	
	return PLUGIN_HANDLED;
}

public Update_Number(id)
{
	new newNumber[16], szName[32], szAuthID[32], i;
	read_argv(1, newNumber, 15);
	
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuthID, charsmax(szAuthID));
	
	//CHECKS IF NUMBER IS CORRECT OR NOT
	for(i = 0; i < sizeof(gBlockTexts); i++)
	{ 
		if(containi(newNumber, gBlockTexts[i]) != -1) 
		{ 
			ColorChat(id, "%L",LANG_PLAYER, "WRONG_NUM");
			client_cmd(id, "spk buttons/button10.wav");
			return PLUGIN_HANDLED;
		} 
	} 
    
	for(i = 0; i <= strlen(newNumber); i++)
	{
		if(isalpha(newNumber[i]))
		{
				ColorChat(id, "%L",LANG_PLAYER, "WRONG_NUM");
				client_cmd(id, "spk buttons/button10.wav");
				return PLUGIN_HANDLED;
		}
	}
	
	if((strlen(newNumber) < min_digit) || (strlen(newNumber) > max_digit) || ((newNumber[0] == '+')  && (strlen(newNumber) < max_digit)) || ((newNumber[0] != '+') && (strlen(newNumber) > min_digit)))
	{
		ColorChat(id, "%L",LANG_PLAYER, "WRONG_NUM");
		client_cmd(id, "spk buttons/button10.wav");
		return PLUGIN_HANDLED;
	}
	
	new file = fopen(iRequestsFile, "rt");
	if(file) 
	{ 
		new TempFilePath[256];
		formatex(TempFilePath, charsmax(TempFilePath), "addons/amxmodx/configs/tempfile.ini"); 
		
		new tmpfile = fopen(TempFilePath, "at"); 
		if(tmpfile) 
		{ 
			new FileData[128]; 
			while(!feof(file)) 
			{ 
				fgets(file, FileData, charsmax(FileData)); 
				
				if(containi(FileData, szName) != -1 )
				{ 
					fprintf(tmpfile, "-[UPDATE] %s(%s) : %s^n", szName, szAuthID, newNumber);
					continue;
				}
				
				fputs(tmpfile, FileData);
			} 
			
			fclose(tmpfile); 
			fclose(file);
			
			delete_file(iRequestsFile); 
			rename_file(TempFilePath, iRequestsFile, 1);

			ColorChat(id, "%L",LANG_PLAYER, "NUM_UPDATED_MSG_PLAYER");
			client_cmd(0, "spk vox/accepted.wav");
			
			return PLUGIN_HANDLED;
		} 
	} 
	return PLUGIN_HANDLED;
}

public View_Requests(id)
{
	if(!file_exists(iRequestsFile))
	{
		client_print(id, print_console, "%L%L%L", LANG_PLAYER, "MSGC_EXTENDER", LANG_PLAYER, "MSGC_FILE_NOT_EXIST", LANG_PLAYER, "MSGC_EXTENDER");
		return PLUGIN_HANDLED;
	}
	
	new szData[128], file;
	client_print(id, print_console, "%L", LANG_PLAYER, "MSGC_EXTENDER");
	client_print(id, print_console, "%L", LANG_PLAYER, "MSGC_VIEWREQUESTS");
	file = fopen(iRequestsFile, "rt");
	while(!feof(file))
	{
		fgets(file, szData, charsmax(szData));
		trim(szData);
		client_print(id, print_console, szData);
	}
	client_print(id, print_console, "%L", LANG_PLAYER, "MSGC_EXTENDER");
	client_cmd(id, "spk vox/check.wav");
	fclose(file);
	return PLUGIN_HANDLED;
}

public delete_request_handler(id, menu, item)
{
	switch(item)
	{
		case 0 : {
				if(!file_exists(iRequestsFile))
				{
					ColorChat(id, "%L", LANG_PLAYER, "MSG_FILE_NOT_EXIST");
				}
				else
				{
					delete_file(iRequestsFile);
					ColorChat(id, "%L", LANG_PLAYER, "CONFIRM_DLT_YES");
					client_cmd(id, "spk vox/destroyed.wav");
				}
			}
		case 1 : {
				ColorChat(id, "%L", LANG_PLAYER, "CONFIRM_DLT_NO");
			}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
			
stock ColorChat(const id, const szInput[], any:...)
{
	new iPlayers[32], iCount = 1;
	static szMessage[191];
	vformat(szMessage, charsmax(szMessage), szInput, 3);
	format(szMessage[0], charsmax(szMessage), "%s %s",xPrefix, szMessage);
	
	replace_all(szMessage, charsmax(szMessage), "!g", "^4");
	replace_all(szMessage, charsmax(szMessage), "!n", "^1");
	replace_all(szMessage, charsmax(szMessage), "!t", "^3");
	
	if(id)
		iPlayers[0] = id;
	else
		get_players(iPlayers, iCount, "ch");
	
	for(new i, iPlayer; i < iCount; i++)
	{
		iPlayer = iPlayers[i];
		
		if(is_user_connected(iPlayer))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_iSayText, _, iPlayer);
			write_byte(iPlayer);
			write_string(szMessage);
			message_end();
		}
	}
}
