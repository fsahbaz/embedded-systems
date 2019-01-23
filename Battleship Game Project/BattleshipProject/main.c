// Clock configuration
#ifndef F_CPU
#define F_CPU 8000000UL
#endif
// PIN configurations.
#define D4 eS_PORTD4
#define D5 eS_PORTD5
#define D6 eS_PORTD6
#define D7 eS_PORTD7
#define RS eS_PORTC6
#define EN eS_PORTC7
// Necessary libraries
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "lcd.h"
// Fields
int init = 1;
int game = 1;
char s1[5] = "IHH>";
char s2[7] = "IHHHH>";
char s3[3] = "I>";
int avail[6] = {0, 2, 4, 6, 8, 10};
int s1Num[2], s2Num[3], s3Num[1];
int s1Loc, s2Loc, s3Loc;
int s1Holder, s2Holder, s3Holder;
int generalStat = 0;
int totMoves = 0;
int inButA,inButB;
time_t t;
// Methods that support the game logic:
// Initializing pin directions for I/O operations, and also the LCD screen.
int initData()
{
	DDRA = 0x00;
	DDRB = 0x00;

	DDRD = 0xFF;
	DDRC = 0xFF;

	Lcd4_Init();
	return 0;
}
// Reading button inputs (required to shoot the ships).
int readButtons()
{
	inButB = PINB;
	inButA = PINA;
	return 0;
}
// Generating randomized (cursor) locations in order to place the ships starting from
// them.
int initRandPlaces()
{
	srand((unsigned) time(&t));
	s1Holder = avail[rand()%6];
	s2Holder = avail[rand()%6];
	while (s1Holder == s1Loc || s2Holder == s2Loc || s1Holder == s2Holder)
	{
		s1Holder = avail[rand()%6] * avail[rand()%6] % 10;
		s2Holder = avail[rand()%6] * avail[rand()%6] % 10;
	}
	return 0;
}
// Placing the ships in the UI (LCD screen).
int printShip(int row, int col, char ship[])
{
	Lcd4_Set_Cursor(row,col);
	Lcd4_Write_String(ship);
	return 0;
}
// Initializing ships according to their randomized places.
int initShips(int* i)
{
	if(*i)
	{
		s1Loc = s1Holder;
		printShip(1,s1Loc,s1);
		s2Loc = s2Holder;
		printShip(2,s2Loc,s2);
		s3Holder = (s1Holder + 6) % 16;
		s3Loc = s3Holder;
		printShip(1,s3Loc,s3);
		_delay_ms(3000);
		Lcd4_Clear();
		*i = 0;
	}
	return 0;
}
// Placing ships in the domain, according to their cursor locations.
// These locations will be utilized when checking whether the taken shots hit a ship.
int placeShips(int loc1, int loc2)
{
	int starter1 = 0;
	int starter2 = 0;
	switch (loc1)
	{
		case 0: starter1 = 128;
		break;
		case 2: starter1 = 64;
		break;
		case 4: starter1 = 32;
		break;
		case 6: starter1 = 16;
		break;
		case 8: starter1 = 8;
		break;
		case 10: starter1 = 4;
		break;
		default: break;
	}
	switch (loc2)
	{
		case 0: starter2 = 128;
		break;
		case 2: starter2 = 64;
		break;
		case 4: starter2 = 32;
		break;
		case 6: starter2 = 16;
		break;
		case 8: starter2 = 8;
		break;
		case 10: starter2 = 4;
		break;
		default: break;
	}
	for(int i=0; i<2; i++)
	{
		s1Num[i] = starter1/pow(2,i);
	}
	for(int j=0; j<3; j++)
	{
		s2Num[j] = starter2/pow(2,j);
	}
	if (starter1 != 4)
	{
		s3Num[0] = starter1/pow(2,3);
	}
	else
	{
		s3Num[0] == 128;
	}
	return 0;
}
// Printing the shot portion of a ship.
int printDamage(int row, int col, char p1, char p2)
{
	Lcd4_Set_Cursor(row, col);
	Lcd4_Write_Char(p1);
	Lcd4_Write_Char(p2);
	return 0;
}
// Checking whether the button inputs have indeed hit a ship.
int evalButtons(int a, int b)
{
	if(b == 0)
	{
		if (a == s1Num[0])
		{
			if(s1[0] != '#' && s1[1] != '#')
			{
				generalStat = generalStat + 1;
				for(int i=0; i<2; i++)
				{
					s1[i] = '#';
				}
				printDamage(1, s1Loc, s1[0], s1[1]);
			}
		}
		else if (a == s1Num[1])
		{
			if(s1[2] != '#' && s1[3] != '#')
			{
				generalStat = generalStat + 1;
				for(int i=2; i<4; i++)
				{
					s1[i] = '#';
				}
				printDamage(1, s1Loc + 2, s1[2], s1[3]);
			}
		}
		else if (a == s3Num[0])
		{
			if(s3[0] != '#' && s3[1] != '#')
			{
				generalStat = generalStat + 1;
				for(int i=0; i<2; i++)
				{
					s3[i] = '#';
				}
				printDamage(1, s3Loc, s3[0], s3[1]);
			}
		}
	}
	else
	{
		if (b == s2Num[0])
		{
			if(s2[0] != '#' && s2[1] != '#')
			{
				generalStat = generalStat + 1;
				for(int i=0; i<2; i++)
				{
					s2[i] = '#';
				}
				printDamage(2, s2Loc, s2[0], s2[1]);
			}
		}
		else if (b == s2Num[1])
		{
			if(s2[2] != '#' && s2[3] != '#')
			{
				generalStat = generalStat + 1;
				for(int i=2; i<4; i++)
				{
					s2[i] = '#';
				}
				printDamage(2, s2Loc + 2, s2[2], s2[3]);
			}
		}
		else if (b == s2Num[2])
		{
			if(s2[4] != '#' && s2[5] != '#')
			{
				generalStat = generalStat + 1;
				for(int i=4; i<6; i++)
				{
					s2[i] = '#';
				}
				printDamage(2, s2Loc + 4, s2[4], s2[5]);
			}
		}
	}
	return 0;
}
// Resetting ship data.
int resetShips()
{
	strcpy(s1,"IHH>");
	strcpy(s2,"IHHHH>");
	strcpy(s3,"I>");
	return 0;
}
// Resetting fields that are necessary to reinitiate the game.
int resetStats()
{
	generalStat = 0;
	totMoves = 0;
	init = 1;
	game = 1;
	return 0;
}
// Displaying results (and win/lose state) according to the total move count.
// total > 6 => lost.
int displayResult(int total)
{
	Lcd4_Clear();
	
	char str[50];
	sprintf(str,"%d",total);
	char message[50] = "Moves: ";
	strcat(message,str);
	Lcd4_Set_Cursor(1,3);
	Lcd4_Write_String(message);

	if(total > 6)
	{
		Lcd4_Set_Cursor(2,3);
		Lcd4_Write_String("Game lost.");
	}
	else
	{
		Lcd4_Set_Cursor(2,3);
		Lcd4_Write_String("Game won!");
	}
	_delay_ms(1000);
	Lcd4_Clear();
	return 0;
}
// Ending a turn of the game.
int endSession()
{
	game = 0;
	Lcd4_Clear();
	resetShips();
	resetStats();
	_delay_ms(1000);
	return 0;
}
// Printing a given message on the LCD.
int printMessage(int row, int col, char msg[])
{
	Lcd4_Set_Cursor(row,col);
	Lcd4_Write_String(msg);
	return 0;
}
// Main game flow.
int main(void)
{
	
	initData();

	while(1)
	{
		while(game)
		{
			initRandPlaces();
			initShips(&init);
			placeShips(s1Loc, s2Loc);
			readButtons();
			if (inButA != 0 || inButB != 0) // Debouncing actually.
			{
				evalButtons(inButA, inButB);
				totMoves++;
				_delay_ms(500); // was necessary in order to observe the last shot before the ship sinks.
			}
			if (generalStat == 6)
			{
				int endGame = 0;
				displayResult(totMoves);
				_delay_ms(1000);
				Lcd4_Clear();
				while(!endGame)
				{
					printMessage(1,1,"Play again?");
					printMessage(2,1,"(y/n : B1/B0)");
					readButtons();
					if (inButB == 1)
					{
						Lcd4_Clear();
						printMessage(2,3,"Bye!");
						_delay_ms(1000);
						return 0;
					}
					else if (inButB == 2)
					{
						Lcd4_Clear();
						printMessage(2,3,"Reloading.");
						_delay_ms(1000);
						endGame = 1;
					}
				}
				endSession();
				break;
			}
		}
	}
}