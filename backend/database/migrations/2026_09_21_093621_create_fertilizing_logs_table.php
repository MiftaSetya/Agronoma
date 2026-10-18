<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('fertilizing_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_plant_id')->constrained('user_plants')->cascadeOnDelete();
            $table->date('scheduled_date');
            $table->date('actual_date')->nullable();
            $table->enum('status', ['fertilized', 'delayed_rain', 'missed']);
            $table->string('fertilizer_description')->nullable();
            $table->timestamps();
            $table->index(['user_plant_id', 'scheduled_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fertilizing_logs');
    }
};
