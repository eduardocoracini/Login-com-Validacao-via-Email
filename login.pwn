#include <a_samp>
#include <a_http>

#define DIALOG_REGISTER			5000
#define DIALOG_LOGIN			5001
#define DIALOG_EMAIL			5002
#define DIALOG_TOKEN			5003
#define DATABASE_NAME			"users.db"
#define PHP_URL				"localhost/teste/send-token.php?Email=%s&Token=%i"

enum E_PLAYER
{
	Nome[MAX_PLAYER_NAME + 1],
	Senha[65],
	Email[128],
	Matou,
	Morreu
}
new _player[MAX_PLAYERS][E_PLAYER];
new DB:_dbHandle;

public OnFilterScriptInit()
{
	ConfigDatabase();
}

public OnPlayerConnect(playerid)
{
	new caption[65], name[MAX_PLAYER_NAME + 1], selectStr[128];
	
	GetPlayerName(playerid, name, sizeof name);
	strcat(_player[playerid][Nome], name, sizeof name);
	
	format(selectStr, sizeof selectStr, "SELECT token FROM usuarios WHERE nome = '%s'", _player[playerid][Nome]);
	new DBResult:result = db_query(_dbHandle, selectStr);
	
	if(db_num_rows(result) > 0)
	{
		new token = db_get_field_assoc_int(result, "token");
		if(token != 0)
		{
			ShowPlayerDialog(playerid, DIALOG_TOKEN, DIALOG_STYLE_INPUT, "Insira o token abaixo:", "Você não finalizou a ativação da conta!\n\nPara finalizar seu cadastro, entre no seu e-mail cadastrado e copie e cole aqui o token fornecido.\nO e-mail pode demorar alguns minutos para chegar.\n* Verifique a caixa de spam!\n\nClique em \"REGISTRAR\" para finalizar o cadastro.", "REGISTRAR", "SAIR");
			db_free_result(result);
			return false;
		}
				
		format(caption, sizeof caption, "Seja bem vindo(a) novamente, %s!", _player[playerid][Nome]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, caption, "Clique em \"LOGAR\" para continuar o progresso de sua conta.", "LOGAR", "SAIR");
	}
	else
	{
		format(caption, sizeof caption, "Seja bem vindo(a), %s!", _player[playerid][Nome]);
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, caption, "Você ainda não possui conta conosco.\nClique em \"REGISTRAR\" para criar sua nova conta.", "REGISTRAR", "SAIR");
	}
	
	db_free_result(result);
	return true;
}

public OnPlayerDisconnect(playerid, reason)
{
	SaveData(playerid);
	
	_player[playerid][Nome] = '\0';
	_player[playerid][Senha] = '\0';
	_player[playerid][Matou] = 0;
	_player[playerid][Morreu] = 0;
	return false;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	_player[playerid][Morreu] ++;
	_player[killerid][Matou] ++;
	return true;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_LOGIN)
	{
		new caption[65], selectStr[128];
		
		if(response)
		{
			if(!strlen(inputtext))
			{
				format(caption, sizeof caption, "Seja bem vindo(a) novamente, %s!", _player[playerid][Nome]);
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, caption, "Senha inválida!\n\nClique em \"LOGAR\" para continuar o progresso de sua conta.", "LOGAR", "SAIR");
				return false;
			}
			
			SHA256_PassHash(inputtext, "salt123", _player[playerid][Senha], 65);
			
			format(selectStr, sizeof selectStr, "SELECT * FROM usuarios WHERE nome = '%s' AND senha = '%s'", _player[playerid][Nome], _player[playerid][Senha]);
			new DBResult:result = db_query(_dbHandle, selectStr);
			
			if(db_num_rows(result) > 0)
			{
				new token = db_get_field_assoc_int(result, "token");
				if(token != 0)
				{
					ShowPlayerDialog(playerid, DIALOG_TOKEN, DIALOG_STYLE_INPUT, "Insira o token abaixo:", "Você não finalizou a ativação da conta!\n\nPara finalizar seu cadastro, entre no seu e-mail cadastrado e copie e cole aqui o token fornecido.\nO e-mail pode demorar alguns minutos para chegar.\n* Verifique a caixa de spam!\n\nClique em \"REGISTRAR\" para finalizar o cadastro.", "REGISTRAR", "SAIR");
					db_free_result(result);
					return false;
				}
				
				LoadData(playerid, result);
				SendClientMessage(playerid, -1, "Logado com sucesso!");
			}
			else
			{
				format(caption, sizeof caption, "Seja bem vindo(a) novamente, %s!", _player[playerid][Nome]);
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, caption, "Senha inválida!\n\nClique em \"LOGAR\" para continuar o progresso de sua conta.", "LOGAR", "SAIR");
			}
			
			db_free_result(result);
		}
		else
			Kick(playerid);
	}
	else if(dialogid == DIALOG_REGISTER)
	{
		new caption[65];
		
		if(response)
		{
			if(strlen(inputtext) < 7)
			{
				format(caption, sizeof caption, "Seja bem vindo(a), %s!", _player[playerid][Nome]);
				ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, caption, "A senha deve conter, no mínimo, 8 caracteres.\n\nVocê ainda não possui conta conosco.\nClique em \"AVANÇAR\" para ir à próxima etapa.", "AVANÇAR", "SAIR");
				return false;
			}
			
			SHA256_PassHash(inputtext, "salt123", _player[playerid][Senha], 65);
			ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Insira seu e-mail:", "Insira um e-mail válido.\nLembre-se: Um token será enviado ao seu endereço de e-mail para finalizar o cadastro.\nClique em \"AVANÇAR\" para ir à próxima etapa.", "AVANÇAR", "VOLTAR");
		}
		else
			Kick(playerid);
	}
	else if(dialogid == DIALOG_EMAIL)
	{
		new caption[65];
		
		if(response)
		{
			if(strlen(inputtext) < 5)
			{
				ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Insira seu e-mail:", "Insira um e-mail válido.\nLembre-se: Um token será enviado ao seu endereço de e-mail para finalizar o cadastro.\nClique em \"AVANÇAR\" para ir à próxima etapa.", "AVANÇAR", "VOLTAR");
				return false;
			}
			
			strcat(_player[playerid][Email], inputtext, 150);
			CreateAccount(playerid);
		}
		else
		{
			format(caption, sizeof caption, "Seja bem vindo(a), %s!", _player[playerid][Nome]);
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, caption, "A senha deve conter, no mínimo, 8 caracteres.\n\nVocê ainda não possui conta conosco.\nClique em \"AVANÇAR\" para ir à próxima etapa.", "AVANÇAR", "SAIR");
		}
	}
	else if(dialogid == DIALOG_TOKEN)
	{
		new updateStr[128];
		
		if(response)
		{
			if(!strlen(inputtext))
			{
				ShowPlayerDialog(playerid, DIALOG_TOKEN, DIALOG_STYLE_INPUT, "Insira o token abaixo:", "Para finalizar seu cadastro, entre no seu e-mail cadastrado e copie e cole aqui o token fornecido.\nO e-mail pode demorar alguns minutos para chegar.\n* Verifique a caixa de spam!\n\nClique em \"REGISTRAR\" para finalizar o cadastro.", "REGISTRAR", "SAIR");
				return false;
			}
			
			if(IsValidToken(playerid, strval(inputtext)) == 0)
			{
				ShowPlayerDialog(playerid, DIALOG_TOKEN, DIALOG_STYLE_INPUT, "Insira o token abaixo:", "Token inválido!\n\nPara finalizar seu cadastro, entre no seu e-mail cadastrado e copie e cole aqui o token fornecido.\nO e-mail pode demorar alguns minutos para chegar.\n* Verifique a caixa de spam!\n\nClique em \"REGISTRAR\" para finalizar o cadastro.", "REGISTRAR", "SAIR");
			}
			else
			{
				format(updateStr, sizeof updateStr, "UPDATE usuarios SET token = 0 WHERE nome = '%s'", _player[playerid][Nome]);
				db_query(_dbHandle, updateStr);
				
				SendClientMessage(playerid, -1, "Cadastro finalizado com sucesso!");
			}
		}
		else
			Kick(playerid);
	}
	
	return true;
}

ConfigDatabase()
{
	_dbHandle = db_open(DATABASE_NAME);
	if(_dbHandle)
	{
		db_query(_dbHandle, "CREATE TABLE usuarios (\
		  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
		  nome TEXT NOT NULL,\
		  senha TEXT NOT NULL,\
		  email TEXT NOT NULL,\
		  matou integer NOT NULL DEFAULT 0,\
		  morreu integer NOT NULL DEFAULT 0,\
		  token TEXT)");
	}
	else
	{
		print("\n______________________________________Não foi possível abrir o banco de dados!\n______________________________________\n");
		SendRconCommand("GMX");
	}
}

LoadData(playerid, DBResult:result)
{
	if(result)
	{
		_player[playerid][Matou] = db_get_field_assoc_int(result, "matou");
		_player[playerid][Morreu] = db_get_field_assoc_int(result, "morreu");
	}
}

CreateAccount(playerid)
{
	new 
		url[250],
		rndToken = random(99999 - 11111) + 11111;
	
	new dataStr[300];
	format(dataStr, sizeof dataStr, "INSERT INTO usuarios (nome, senha, email, token) VALUES ('%s', '%s', '%s', '%i')",
	_player[playerid][Nome],
	_player[playerid][Senha],
	_player[playerid][Email],
	rndToken);
	db_query(_dbHandle, dataStr);
	
	SendClientMessage(playerid, -1, "Sua conta foi criada com sucesso! Agora basta a ativar para iniciar seu jogo.");
	SendClientMessage(playerid, -1, "Enviando token...");
	
	format(url, sizeof url, PHP_URL, _player[playerid][Email], rndToken);
	HTTP(playerid, HTTP_GET, url, "", "SendAccountToken");
}

SaveData(playerid)
{
	new dataStr[200];
	format(dataStr, sizeof dataStr, "UPDATE usuarios SET senha = '%s', matou = '%i', morreu = '%i' WHERE nome = '%s'",
	_player[playerid][Senha],
	_player[playerid][Matou],
	_player[playerid][Morreu],
	_player[playerid][Nome]);
	db_query(_dbHandle, dataStr);
}

IsValidToken(playerid, token)
{
	new 
		exists = 0,
		selectStr[128];
	
	format(selectStr, sizeof selectStr, "SELECT token FROM usuarios WHERE nome = '%s' AND token = '%i'", _player[playerid][Nome], token);
	new DBResult:result = db_query(_dbHandle, selectStr);
	exists = db_num_rows(result);
	db_free_result(result);
	return exists;
}

forward SendAccountToken(index, response_code, data[]);
public SendAccountToken(index, response_code, data[])
{
    if (response_code == 200)
    {
    	new caption[65];
    	
		SendClientMessage(index, -1, "Em breve você receberá um e-mail contendo um token que deverá ser informado na caixa de diálogo.");
		
		format(caption, sizeof caption, "Insira o token abaixo:", _player[index][Nome]);
		ShowPlayerDialog(index, DIALOG_TOKEN, DIALOG_STYLE_INPUT, caption, "Para finalizar seu cadastro, entre no seu e-mail cadastrado e copie e cole aqui o token fornecido.\nO e-mail pode demorar alguns minutos para chegar.\n* Verifique a caixa de spam!\n\nClique em \"REGISTRAR\" para finalizar o cadastro.", "REGISTRAR", "SAIR");
	}
	else
		SendClientMessage(index, -1, "Houve uma instabilidade em nosso servidor e não foi possível enviar o token. Fale com a administração.");
    
    return true;
}
