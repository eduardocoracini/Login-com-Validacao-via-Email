<?php
if(empty($_GET["Email"]) || empty($_GET["Token"]))
    die(0);

$Email = $_GET["Email"];
$Token = $_GET["Token"];

require "PHPMailer/PHPMailer.php";
require "PHPMailer/SMTP.php";
require "PHPMailer/Exception.php";

$mail = new \PHPMailer\PHPMailer\PHPMailer();
$mail->isSMTP();
$mail->Host = "smtp.office365.com";
$mail->SMTPAuth = true;
$mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
$mail->setLanguage("pt");
$mail->CharSet = PHPMailer\PHPMailer\PHPMailer::CHARSET_UTF8;
$mail->Username = "email@hotmail.com"; // E-mail outlook
$mail->Password = "pwd123"; // Senha da conta
$mail->Port = 587;

$mail->setFrom("email@hotmail.com"); // E-mail outlook
$mail->addAddress($Email);
$mail->isHTML(true);
$mail->Subject = "Token de ativação - SA:MP";
$mail->Body = "Bem vindo ao servidor!<br>O seu token é: <b>{$Token}</b>";

if(!$mail->send())
    echo 0;
else
    echo 1;

