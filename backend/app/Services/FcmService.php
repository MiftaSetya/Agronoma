<?php

namespace App\Services;

use Kreait\Firebase\Exception\FirebaseException;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Messaging;

class FcmService
{
    private ?Messaging $messaging = null;

    public function __construct()
    {
        $credentials = config('services.firebase.credentials');

        if ($credentials !== null && is_file($credentials)) {
            $this->messaging = (new Factory)
                ->withServiceAccount($credentials)
                ->createMessaging();
        }
    }

    public function isAvailable(): bool
    {
        return $this->messaging !== null;
    }

    public function send(array|string|null $tokens, string $title, string $body, array $data = []): void
    {
        if ($this->messaging === null || $tokens === null || $tokens === []) {
            return;
        }

        foreach ((array) $tokens as $token) {
            $message = CloudMessage::fromArray([
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $data,
            ]);

            try {
                $this->messaging->send($message);
            } catch (FirebaseException) {

                continue;
            }
        }
    }
}
