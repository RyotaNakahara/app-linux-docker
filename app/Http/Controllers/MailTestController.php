<?php

namespace App\Http\Controllers;

use App\Mail\TestMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class MailTestController extends Controller
{
    public function send()
    {
        $recipient = 'test@example.com';

        Mail::to($recipient)->send(new TestMail());

        return response()->json([
            'message' => 'テストメールが送信されました',
            'recipient' => $recipient,
            'mailhog_url' => 'http://localhost:8025',
        ]);
    }
}

