<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('pest_scan_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('user_plant_id')->nullable()->constrained('user_plants')->nullOnDelete();
            $table->string('image_url');
            $table->string('detected_pest_name')->nullable();
            $table->decimal('ai_confidence', 5, 2)->nullable();
            $table->json('ai_raw_response')->nullable();
            $table->text('recommended_action')->nullable();
            $table->timestamp('scanned_at')->useCurrent();
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pest_scan_history');
    }
};
